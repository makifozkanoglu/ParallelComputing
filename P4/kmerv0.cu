#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <sys/wait.h> 
#include <unistd.h> 
#include <util.h>
__device__ int cuda_strlen(const char* string){
    int length = 0;
    while (*string++)
        length++;

    return (length);
}
__device__ int ipow_cuda(int x,int y){

    int result = 1;

    //for(int i = y; i>0; i--) result *= x;
    while (y != 0) {
        result *= x;
        --y;
    }
    return result;
}
__host__ void kmer_starts(StringList &queries,
                          ResultDict &result,
                          char *reference, int k, 
                          int ref_length,
                          int NUMBER_OF_CUDA_THREADS
                          );
__device__ int get_query_idx(char *query, int k);

__global__ void search(char **line_queries_array, int line_queries_used, 
            char *reference, int k, 
            int ref_length, int **r_idxs,
            int **r_line_idx,
            int **r_pat_idx,
            int **r_query_idx,
            int **r_hits,
            int **r_extension_scores, int NUMBER_OF_CUDA_THREADS,
            int *idxs,
            int *line_idx,
            int *pat_idx,
            int *query_idx,
            int *hits,
            int *extension_scores);
            
__device__  void updateResultDict_cuda(
            int *r_idxs,
            int *r_line_idx,
            int *r_pat_idx,
            int *r_hits,
            int *r_extension_scores,
            int idx, int query_idx, 
            int line_idx,int pat_idx, 
            int extension_score);

int main(int argc, char *argv[]){
    clock_t start = clock(), diff;
    int row_size,col_size,value_size;
    
        if(argc != 5) {
        printf("Wrong argments usage: ./kmer [REFERENCE_FILE] [READ_FILE] [k] [OUTPUT_FILE]\n" );
    }

    
    FILE *fp;
    int k;

    //malloc instead of allocating in stack
    char *reference_str = (char*) malloc(MAX_REF_LENGTH * sizeof(char));
    char *read_str = (char*) malloc(MAX_READ_LENGTH * sizeof(char));

    
    char reference_filename[]= "/home/akif/Parallel/P4/data/ref.txt";char read_filename[]= "/home/akif/Parallel/P4/ddata/reads_9216_100bp.txt"; char output_filename[]= "s";k = 3;
    int reference_length;
    /*
    char *reference_filename, *read_filename, *output_filename;
    reference_filename = argv[1];
    read_filename =argv[2];
    k = atoi(argv[3]);
    output_filename = argv[4];
    */



    fp = fopen(reference_filename, "r");
    if (fp == NULL) {
        printf("Could not open file %s!\n",reference_filename);
        return 1;
    }

    if (fgets(reference_str, MAX_REF_LENGTH, fp) == NULL) { //A single line only
        printf("Problem in file format!\n");
        return 1;
    }

    substring(reference_str, 0, strlen(reference_str)-1);
    //printf("Reference str is = %s\n", reference_str);
    fclose(fp);

    //Read queries
    StringList queries;

    initStringList(&queries, 3);  // initially 3 elements
      
    int success = read_file(read_filename,&queries);
    //for (int i=0;i<queries.used;i++)//{
    //   printf("Reference str is = %s for %d idx\n", queries.array[i],i);
    //}
      
    reference_length = strlen(reference_str); //Last character is '\n'
    
    ResultDict result;
    initResultDict(&result, k);

    const int NUMBER_OF_CUDA_THREADS = 128; //* 1024;
    //int blocksize = 512; // value usually chosen by tuning and hardware constraints
    //int nblocks = NUMBER_OF_CUDA_THREADS / blocksize; // value determine by block size and total work
    //madd<<<nblocks,blocksize>>>mAdd(A,B,C,n);

    printf("Searching\n");
    kmer_starts(queries,result,reference_str,k,reference_length,NUMBER_OF_CUDA_THREADS);
    
    for (int i=0;i<result.size;i++){
        if(result.hits[i]){
            printf("i:%d,idx:%d %s, hit:%d, extension_score:%d \n",
            i,result.idxs[i], 
            result.queries[i],
            result.hits[i],
            result.extension_scores[i]);
        }
    }
    //Free up
    freeResultDict(&result);
    freeStringList(&queries);

    free(reference_str);
    free(read_str);
    diff = clock() - start;
    int msec = diff * 1000 / CLOCKS_PER_SEC;
    printf("----\nTime taken: %d seconds %d milliseconds\n", msec/1000, msec%1000);

    return 0;

}

/*
__host__ void kmer_starts(StringList &queries,
                          ResultDict &result,
                          char *reference, int k, 
                          int ref_length,
                          int NUMBER_OF_CUDA_THREADS
                          )
{
    int query_size=ipow(4,k);

    // ... Successfully read from file into "data" ...
    StringList* h_queries = (StringList*)malloc(sizeof(StringList));
    memcpy(h_queries, &queries, 34 * sizeof(StringList);

    for (int i=0; i<numMat; i++){

        cudaMalloc(&(h_data[i].elements), rows*cols*sizeof(float));
        cudaMemcpy(h_data[i].elements, data[i].elements,  rows*cols*sizeof(float)), cudaMemcpyHostToDevice);

     }// matrix data is now on the gpu, now copy the "meta" data to gpu
     Matrix* d_data;
     cudaMalloc(&d_data, numMat*sizeof(Matrix)); 
     cudaMemcpy(d_data, h_data, numMat*sizeof(Matrix));
}
*/
__host__ void kmer_starts(StringList &queries,
                          ResultDict &result,
                          char *reference_str, int k, 
                          int reference_length,
                          const int NUMBER_OF_CUDA_THREADS){

    char **c_line_queries_array; //int c_line_queries_used;
    char *c_reference;
    int size;

    size=reference_length * sizeof(char);
    cudaMalloc((void**)&c_reference, size);
    cudaMemcpy(c_reference, reference_str, size, cudaMemcpyHostToDevice);
    
    //char **d_data;

    cudaMalloc(&c_line_queries_array, queries.used*sizeof(char *));
    char **d_temp_data;
    d_temp_data = (char **)malloc(queries.used*sizeof(char *));
    for (int i = 0; i < queries.used; i++){
        cudaMalloc(&(d_temp_data[i]), MAX_READ_LENGTH*sizeof(char));
        cudaMemcpy(d_temp_data[i], queries.array[i], MAX_READ_LENGTH*sizeof(char), cudaMemcpyHostToDevice);
        cudaMemcpy(c_line_queries_array+i, &(d_temp_data[i]), sizeof(char *), cudaMemcpyHostToDevice);
    }
    free(d_temp_data);
    
    //////////////////Results//////////////////
    int number_of_queries = ipow(4,k); 
    size = number_of_queries * sizeof(int);
    

    int **r_line_idx;
    //cudaMalloc((void**)&r_line_idx, size);
    //cudaMemcpy(r_line_idx, result.line_idx, size, cudaMemcpyHostToDevice);
    cudaMalloc(&r_line_idx, NUMBER_OF_CUDA_THREADS*sizeof(int *));
    int **t_line_idx;
    t_line_idx = (int **)malloc(NUMBER_OF_CUDA_THREADS*sizeof(int *));
    for (int i = 0; i < NUMBER_OF_CUDA_THREADS; i++){
        cudaMalloc(&(t_line_idx[i]), size);
        cudaMemcpy(t_line_idx[i], result.line_idx, size, cudaMemcpyHostToDevice);
        cudaMemcpy(r_line_idx+i, &(t_line_idx[i]), sizeof(int *), cudaMemcpyHostToDevice);
    }
    



    int **r_idxs;
    //cudaMalloc((void**)&r_idxs, size);
    //cudaMemcpy(r_idxs, result.idxs, size, cudaMemcpyHostToDevice);
    cudaMalloc(&r_idxs, NUMBER_OF_CUDA_THREADS*sizeof(int *));
    
    int **t_idxs_data;
    t_idxs_data = (int **)malloc(NUMBER_OF_CUDA_THREADS*sizeof(int *));
    for (int i = 0; i < NUMBER_OF_CUDA_THREADS; i++){
        cudaMalloc(&(t_idxs_data[i]), size);
        cudaMemcpy(t_idxs_data[i], result.idxs, size, cudaMemcpyHostToDevice);
        cudaMemcpy(r_idxs+i, &(t_idxs_data[i]), sizeof(int *), cudaMemcpyHostToDevice);
    }
     
    
    int **r_pat_idx;
    //cudaMalloc((void**)&r_pat_idx, size);
    //cudaMemcpy(r_pat_idx, result.pat_idx, size, cudaMemcpyHostToDevice);
    cudaMalloc(&r_pat_idx, NUMBER_OF_CUDA_THREADS*sizeof(int *));

    int **t_pat_idx;
    t_pat_idx = (int **)malloc(NUMBER_OF_CUDA_THREADS*sizeof(int *));
    for (int i = 0; i < NUMBER_OF_CUDA_THREADS; i++){
        cudaMalloc(&(t_pat_idx[i]), size);
        cudaMemcpy(t_pat_idx[i], result.pat_idx, size, cudaMemcpyHostToDevice);
        cudaMemcpy(r_pat_idx+i, &(t_pat_idx[i]), sizeof(int *), cudaMemcpyHostToDevice);
    }



    int **r_query_idx;
    //cudaMalloc((void**)&r_query_idx, size);
    //cudaMemcpy(r_query_idx, result.query_idx, size, cudaMemcpyHostToDevice);
    cudaMalloc(&r_query_idx, NUMBER_OF_CUDA_THREADS*sizeof(int *));
    int **t_query_idx;
    t_query_idx = (int **)malloc(NUMBER_OF_CUDA_THREADS*sizeof(int *));
    for (int i = 0; i < NUMBER_OF_CUDA_THREADS; i++){
        cudaMalloc(&(t_query_idx[i]), size);
        cudaMemcpy(t_query_idx[i], result.query_idx, size, cudaMemcpyHostToDevice);
        cudaMemcpy(r_query_idx+i, &(t_query_idx[i]), sizeof(int *), cudaMemcpyHostToDevice);
    }



    int **r_hits;
    //cudaMalloc((void**)&r_hits, size);
    //cudaMemcpy(r_hits, result.hits, size, cudaMemcpyHostToDevice);
    cudaMalloc(&r_hits, NUMBER_OF_CUDA_THREADS*sizeof(int *));
    int **t_hits;
    t_hits = (int **)malloc(NUMBER_OF_CUDA_THREADS*sizeof(int *));
    for (int i = 0; i < NUMBER_OF_CUDA_THREADS; i++){
        cudaMalloc(&(t_hits[i]), size);
        cudaMemcpy(t_hits[i], result.hits, size, cudaMemcpyHostToDevice);
        cudaMemcpy(r_hits+i, &(t_hits[i]), sizeof(int *), cudaMemcpyHostToDevice);
    }
    
    int **r_extension_scores;
    //cudaMalloc((void**)&r_extension_scores, size);
    //cudaMemcpy(r_extension_scores, result.extension_scores, size, cudaMemcpyHostToDevice);
    cudaMalloc(&r_extension_scores, NUMBER_OF_CUDA_THREADS*sizeof(int *));
    int **t_extension_scores;
    t_extension_scores = (int **)malloc(NUMBER_OF_CUDA_THREADS*sizeof(int *));
    for (int i = 0; i < NUMBER_OF_CUDA_THREADS; i++){
        cudaMalloc(&(t_extension_scores[i]), size);
        cudaMemcpy(t_extension_scores[i], result.extension_scores, size, cudaMemcpyHostToDevice);
        cudaMemcpy(r_extension_scores+i, &(t_extension_scores[i]), sizeof(int *), cudaMemcpyHostToDevice);
    }
   

    
    //free(t_extension_scores);
    int blocksize = NUMBER_OF_CUDA_THREADS; // value usually chosen by tuning and hardware constraints
    int nblocks = NUMBER_OF_CUDA_THREADS / blocksize; // value determine by block size and total work
    int *idxs;
    
    int *line_idx;
    int *pat_idx;
    int *query_idx;
    int *hits;
    int *extension_scores;
    size = number_of_queries*sizeof(int);
    cudaMalloc((void **)&idxs, size);
    cudaMalloc((void **)&line_idx, size);
    cudaMalloc((void **)&pat_idx, size);
    cudaMalloc((void **)&query_idx, size);
    cudaMalloc((void **)&hits, size);
    cudaMalloc((void **)&extension_scores, size);
    //////////////////Results//////////////////
    search<<<nblocks,blocksize>>>(c_line_queries_array, 
                        queries.used, 
                        c_reference, 
                        k, 
                        reference_length, 
                        r_idxs,
                        r_line_idx,
                        r_pat_idx,
                        r_query_idx,
                        r_hits,
                        r_extension_scores,
                        NUMBER_OF_CUDA_THREADS,
                        idxs,
                        line_idx,
                        pat_idx,
                        query_idx,
                        hits,
                        extension_scores
                        );

   /*for (int i=0;i<2;i++){
        if(hits[i]|| 1){
            printf("i:%d,idx:%d %s, hit:%d, extension_score:%d \n",
            i,result.idxs[i], 
            result.queries[i],
            result.hits[i],
        result.extension_scores[i]);
        }
    }*/
    //__syncthreads();
    cudaDeviceSynchronize();
    /*
    printf("size1:%lu, size2:%lu",sizeof(result.idxs),sizeof(idxs));
    cudaMemcpy(result.idxs, idxs, number_of_queries*sizeof(int), cudaMemcpyDeviceToHost);
    cudaMemcpy(result.line_idx, line_idx, number_of_queries*sizeof(int), cudaMemcpyDeviceToHost);
    cudaMemcpy(result.pat_idx, pat_idx, number_of_queries*sizeof(int), cudaMemcpyDeviceToHost);
    cudaMemcpy(result.query_idx, query_idx, number_of_queries*sizeof(int), cudaMemcpyDeviceToHost);
    cudaMemcpy(result.hits, hits, number_of_queries*sizeof(int), cudaMemcpyDeviceToHost);
    cudaMemcpy(result.extension_scores, extension_scores, number_of_queries*sizeof(int), cudaMemcpyDeviceToHost);
    printf("copyyyyy\n");
    for (int i=0;i<21;i++){
        if(result.hits[i]|| 1){
            printf("i:%d,idx:%d %s, hit:%d, extension_score:%d \n",
            i,result.idxs[i], 
            result.queries[i],
            result.hits[i],
        result.extension_scores[i]);
        }
    }
    */
    //syncthreads();
    /*
    int idx=0, max=0;
    for(int i=0;i<5;i++){
        for(int j=0;j<5;j++){
            if (r_extension_scores[j][i]>max){
                max = r_extension_scores[j][i];
                idx = j;
            }
        }
        if (r_hits[idx][i]>0){
            int query_idx = i;//r_query_idx[idx][i]
            result.extension_scores[query_idx]=r_extension_scores[idx][i];
            result.idxs[query_idx]=idx;
            result.line_idx[query_idx]=r_line_idx[idx][i];
            result.pat_idx[query_idx]=r_pat_idx[idx][i];
            result.hits[query_idx]=r_hits[idx][i];
        }
    }
    
    */
    /*
    cudaFree(c_line_queries_array);
    cudaFree(c_reference);
    cudaFree(r_idxs);
    cudaFree(r_line_idx);
    cudaFree(r_pat_idx);
    cudaFree(r_query_idx);
    cudaFree(r_hits);
    cudaFree(r_extension_scores);
    */

}



__global__ void search(char **line_queries_array, int line_queries_used, 
            char *reference, 
            int k, 
            int ref_length,
            int **r_idxs,
            int **r_line_idx,
            int **r_pat_idx,
            int **r_query_idx,
            int **r_hits,
            int **r_extension_scores,
            int NUMBER_OF_CUDA_THREADS,
            int *idxs,
            int *line_idxs,
            int *pat_idxs,
            int *query_idxs,
            int *hits,
            int *extension_scores)
{
    int tid=blockDim.x*blockIdx.x+threadIdx.x;
    //printf("%d\n",tid);
    int quo=line_queries_used/NUMBER_OF_CUDA_THREADS;
    int remainder=line_queries_used%NUMBER_OF_CUDA_THREADS;
    int batch_size=(remainder<tid)?quo+1:quo;
    int start_idx;
    if(tid<remainder){
        start_idx=tid*(quo+1);
    } else {
        start_idx=tid*quo+remainder;//remainder*(quo+1)+(tid-remainder)*quo;
    }
    //for(int m=0;m<3;m++) printf("%d",m);
    //printf("okk%d %s \n", batch_size,line_queries_array[0]);
    //for (int line_idx=0; line_idx<line_queries_used; line_idx++){
    for (int l_idx=0; l_idx<batch_size; l_idx++){
        char *pat_text = line_queries_array[l_idx+start_idx];
        //char *pat;
        int pat_len = cuda_strlen(pat_text);
        //printf("hbb:%s, %d\n",pat_text, pat_len);
        //printf("line idx=%d, %s \n", line_idx,pat_text);
        for(int p_idx=0;p_idx<=pat_len-k;p_idx++){
            //printf("********************************\n");
            int query_idx = get_query_idx(pat_text+p_idx, k);
            //printf("ok%d %d %s queryidx=%d \n",k, pat_idx,pat_text,query_idx);
            //for (int ts = 0; ts < k; ts++) printf("%c", pat_text[pat_idx+ts]);
            //printf("\n");
            for (int idx = 0; idx <= ref_length - k; idx++) {
                int l;/*
        
                /* For current index idx, check for pattern match */
                for (l = 0; l < k; l++)
                    if (reference[idx + l] != pat_text[p_idx+l])
                        break;
        
                if (l == k){ // if pat[0...k-1] = txt[idx, idx+1, ...idx+k-1]
                    //printf("Pattern found at index %d \n", idx);
  
                    int x=idx+k,y=p_idx+k;
                    int extension_score=k;
                    //while((0<=x)&&(0<=y)&&reference[x]&&pat_text[y]){
                    while((x<ref_length)&&(y<pat_len)&&reference[x]&&pat_text[y]){
                        //printf("ref%cpattern%c\n",reference[x],pat_text[y]);
                        if(reference[x] == pat_text[y])
                            extension_score++;
                        else break;
                        x++;y++;
                    }
                    x=idx-1,y=p_idx-1;

                    while((0<=x)&&(0<=y)&&reference[x]&&pat_text[y]){
                    //while((x<ref_length)&&(y<pat_len)&&reference[x]&&pat_text[y]){
                        if(reference[x] == pat_text[y])
                            extension_score++;
                        else break;
                        x--;y--;
                    }
                    /*
                    if (199>extension_score>150)
                        //printf("extension:%d\n",extension_score);
                    if (extension_score>150){
                        //printf("extension:%d\n refx:%d\n paty=%d\n patter:%s\n",extension_score, x,y,pat_text);
                    }*/
                    //printf("extension:%d\n refx:%d\n paty=%d\n patter:%s\n",extension_score, x,y,pat_text);
                    // calculate query idx and extension score
                    //(r, idx, query_idx, line_idx, pat_idx, extension_score)
                    updateResultDict_cuda(
                                        r_idxs[tid],
                                        r_line_idx[tid],
                                        r_pat_idx[tid],
                                        //r_query_idx,
                                        r_hits[tid],
                                        r_extension_scores[tid],
                                        idx,  
                                        query_idx, 
                                        l_idx, 
                                        p_idx, 
                                        extension_score);

                }
            }
        }

    }
    __syncthreads();
    int idx=0, max=0;
    if(tid==0){
        for(int ii=0;ii<64;ii++){
            max=0,idx=0;
            for(int jj=0;jj<NUMBER_OF_CUDA_THREADS;jj++){
                if (r_extension_scores[jj][ii]>max){
                    max = r_extension_scores[jj][ii];
                    idx = jj;
                }
            }
            if (r_hits[idx][ii]>0){
                int query_idx = ii;//r_query_idx[idx][i]
                extension_scores[query_idx]=r_extension_scores[idx][ii];
                idxs[query_idx]=idx;
                line_idxs[query_idx]=r_line_idx[idx][ii];
                pat_idxs[query_idx]=r_pat_idx[idx][ii];
                hits[query_idx]+=r_hits[idx][ii];
            }
        }
    }
    if(tid==0) //printf("dsaddas");
        for (int i=0;i<64;i++){
            //if(hits[i]|| 1)
                printf("i:%d,idx:%d, hit:%d, extension_score:%d \n",
                i,
                idxs[i], 
                hits[i],
                extension_scores[i]
                );
            
        }
    __syncthreads();
    //insertStringList(result,char *ch='ATC, 4, 4');
}

__device__ int get_query_idx(char *query, int k){
    const char cs[4]={'A','T','G','C'};
    int idx=0;
    int i=0;
    int count=0;
    //printf("wwwwwwwwwww\n");
    for(i=0;i<k;i++){
        int coeff = ipow_cuda(4,k-i-1);
        for(int j=0;j<4;j++){
            //printf("%c",query[i]);
            if (query[i]==cs[j]){
                //printf("yesc:%d   j:%d\n",j,coeff);
                idx+=j*coeff;
                count++;
                break;
            }
        }
        
    }
    //printf("\nwwwwwwwwwww\n");
    if (count!=k)
        return -1;
    else 
        return idx;
}

__device__  void updateResultDict_cuda(
        int *r_idxs,
        int *r_line_idx,
        int *r_pat_idx,
        int *r_hits,
        int *r_extension_scores,
        int idx, int query_idx, 
        int line_idx,int pat_idx, 
        int extension_score)
{   //printf("rexxt%d , %d\n",r_extension_scores[query_idx],extension_score);
    if(r_extension_scores[query_idx]<extension_score){
        r_extension_scores[query_idx]=extension_score;
        r_idxs[query_idx]=idx;
        r_line_idx[query_idx]=line_idx;
        r_pat_idx[query_idx]=pat_idx;
    }
    //printf("rexxt%d , %d\n*********\n",r_extension_scores[query_idx],extension_score);
    r_hits[query_idx]++;
}