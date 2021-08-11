#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <sys/wait.h> 
#include <unistd.h> 
#include <util.h>

__device__ int cuda_strlen(const char* string){
    int length = 0;
    while ( *string && (*string!='\n')){
        length++;
        string++;
    }
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
__global__ void vector_init(int *x,int len,int element){

    for(int i=0;i<len;i++)
        x[i]=element;

}

/*
__global__ void filter_results(int *r_idxs,
            int *r_line_idx,
            int *r_pat_idx,
            int *r_query_idx,
            int *r_hits,
            int *r_extension_scores, int NUMBER_OF_CUDA_THREADS, int number_of_queries){
    int max,idx;
    for(int ii=0;ii<number_of_queries;ii++){
            max=0,idx=0;
            for(int jj=0;jj<NUMBER_OF_CUDA_THREADS;jj++){
                if (r_extension_scores[jj+ii*NUMBER_OF_CUDA_THREADS]>max){
                    max = r_extension_scores[jj+ii*NUMBER_OF_CUDA_THREADS];
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
*/
__device__ char* copy_pattern(char *query_text,int pattern_length){

    char *pattern;
    cudaMalloc(&pattern, pattern_length*sizeof(char));
    //for(int i = y; i>0; i--) result *= x;
    for(int i=0;i<pattern_length;i++)
        pattern[i]=query_text[i];
    return pattern;
}
__host__ void kmer_starts(StringList &queries,
                          ResultDict &result,
                          char *reference, int k, 
                          int ref_length,
                          int NUMBER_OF_CUDA_THREADS,int blocksize
                          );
__device__ int get_query_idx(char *query, int k);

__global__ void search(char *c_queries_flattened, int line_queries_used, 
            char *reference, int k, 
            int ref_length, 
            int *r_idxs,
            int *r_line_idx,
            int *r_pat_idx,
            int *r_query_idx,
            int *r_hits,
            int *r_extension_scores, 
            int NUMBER_OF_CUDA_THREADS,
            int number_of_queries,
            int *idxs,
            int *line_idx,
            int *pat_idx,
            int *query_idx,
            int *hits,
            int *extension_scores,
            int *hold_max_idx);
            
__device__  void updateResultDict_cuda(
            int *r_idxs,
            int *r_line_idx,
            int *r_pat_idx,
            int *r_hits,
            int *r_extension_scores,
            int idx, int query_idx, 
            int line_idx,int pat_idx, 
            int extension_score,int tid,int number_of_queries,int *hold);

int main(int argc, char *argv[]){
    clock_t start = clock(), diff;
    //int row_size,col_size,value_size;
    
    if(argc > 4) {
        printf("Wrong argments usage: ./kmer [REFERENCE_FILE] [READ_FILE] [k] [OUTPUT_FILE]\n" );
    }

    
    FILE *fp;
    int k;

    //malloc instead of allocating in stack
    char *reference_str = (char*) malloc(MAX_REF_LENGTH * sizeof(char));
    char *read_str = (char*) malloc(MAX_READ_LENGTH * sizeof(char));

    /*
    char reference_filename[]= "/home/akif/Parallel/P4/data/ref.txt";
    char read_filename[]= "/home/akif/Parallel/P4/data/reads.txt"; 
    char output_filename[]= "s";k = 3;
    
    */
    int reference_length;
    char *reference_filename, *read_filename, *output_filename;
    reference_filename = argv[1];
    read_filename =argv[2];
    k = atoi(argv[3]);
    output_filename = argv[4];
    


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
    printf("success%d\n",success);
    //for (int i=0;i<queries.used;i++)//{
    //   printf("Reference str is = %s for %d idx\n", queries.array[i],i);
    //}
    
    reference_length = strlen(reference_str); //Last character is '\n'
    int NUMBER_OF_CUDA_THREADS,blocksize;
    ResultDict result;
    initResultDict(&result, k);
     if(argc == 7) {
        NUMBER_OF_CUDA_THREADS = atoi(argv[5]);
        blocksize=atoi(argv[6]); //* 1024;
        printf("Wrong argments usage: ./kmer [REFERENCE_FILE] [READ_FILE] [k] [OUTPUT_FILE]\n" );
    } else {
        NUMBER_OF_CUDA_THREADS =1024;;
        blocksize=16; //* 1024;
    }
    //int blocksize = 512; // value usually chosen by tuning and hardware constraints
    //int nblocks = NUMBER_OF_CUDA_THREADS / blocksize; // value determine by block size and total work
    //madd<<<nblocks,blocksize>>>mAdd(A,B,C,n);

    printf("Searching\n");
    kmer_starts(queries,result,reference_str,k,reference_length,NUMBER_OF_CUDA_THREADS,blocksize);


    fp = fopen (output_filename, "w+");   
    for (int i=0;i<result.size;i++){
        if(result.hits[i]){
            fprintf(fp, "%s, %d, %d\n",
            result.queries[i],
            result.hits[i],
            result.extension_scores[i]);
        }
    }
    fclose(fp);
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


__host__ void kmer_starts(StringList &queries,
                          ResultDict &result,
                          char *reference_str, int k, 
                          int reference_length,
                          const int NUMBER_OF_CUDA_THREADS, int blocksize){

    //char **c_line_queries_array; //int c_line_queries_used;
    char *c_reference;
    int size;
    
    size=reference_length * sizeof(char);
    cudaMalloc((void**)&c_reference, size);
    cudaMemcpy(c_reference, reference_str, size, cudaMemcpyHostToDevice);
    


    int number_of_queries = ipow(4,k);
    int *r_idxs,
        *r_line_idx,
        *r_pat_idx,
        *r_query_idx,
        *r_hits,
        *r_extension_scores;
    size=number_of_queries * NUMBER_OF_CUDA_THREADS  * sizeof(int);
    cudaMalloc((void**)&r_idxs, size);
    cudaMalloc((void**)&r_line_idx, size);
    cudaMalloc((void**)&r_pat_idx, size);
    cudaMalloc((void**)&r_query_idx, size);
    cudaMalloc((void**)&r_hits, size);
    cudaMalloc((void**)&r_extension_scores, size);
    int *hold_max_idx;
    cudaMalloc((void**)&hold_max_idx, size);

    size=number_of_queries * NUMBER_OF_CUDA_THREADS;
    vector_init<<<1,1>>>(hold_max_idx,size,-1);
    vector_init<<<1,1>>>(r_idxs,size,0);
    vector_init<<<1,1>>>(r_line_idx,size,0);
    vector_init<<<1,1>>>(r_pat_idx,size,0);
    vector_init<<<1,1>>>(r_query_idx,size,0);
    vector_init<<<1,1>>>(r_hits,size,0);
    vector_init<<<1,1>>>(r_extension_scores,size,0);
    
    //char **d_data;
    /*
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
   
    */
    
    //free(t_extension_scores);
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
    
    char *queries_flattened = (char*) malloc(queries.used * MAX_READ_LENGTH * sizeof(char));
    for (int i=0;i<queries.used;i++){
        //printf("q%d,s:%s\n",i,queries.array[i]);
        for(int j=0;j<MAX_READ_LENGTH;j++)
            queries_flattened[i*MAX_READ_LENGTH+j]=queries.array[i][j];
    }


    char *c_queries_flattened;
    cudaMalloc((void **)&c_queries_flattened, queries.used*MAX_READ_LENGTH*sizeof(char));
    cudaMemcpy(c_queries_flattened, queries_flattened, queries.used*MAX_READ_LENGTH*sizeof(char), cudaMemcpyHostToDevice);

    //////////////////Results//////////////////
    search<<<nblocks, blocksize>>> (c_queries_flattened, 
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
                                    number_of_queries,
                                    idxs,
                                    line_idx,
                                    pat_idx,
                                    query_idx,
                                    hits,
                                    extension_scores,
                                    hold_max_idx
                                    );


    
    
    cudaMemcpy(result.idxs, idxs, number_of_queries*sizeof(int), cudaMemcpyDeviceToHost);
    cudaMemcpy(result.line_idx, line_idx, number_of_queries*sizeof(int), cudaMemcpyDeviceToHost);
    cudaMemcpy(result.pat_idx, pat_idx, number_of_queries*sizeof(int), cudaMemcpyDeviceToHost);
    cudaMemcpy(result.query_idx, query_idx, number_of_queries*sizeof(int), cudaMemcpyDeviceToHost);
    cudaMemcpy(result.hits, hits, number_of_queries*sizeof(int), cudaMemcpyDeviceToHost);
    cudaError_t error = cudaMemcpy(result.extension_scores, extension_scores, number_of_queries*sizeof(int), cudaMemcpyDeviceToHost);
   // SEGFAULT!!!
   if (error != cudaSuccess){
        printf("cudaMemcpy returned error code %d, line(%d), ErrorString: '%s' \n", error, __LINE__, cudaGetErrorString(error));
        //exit(EXIT_FAILURE);
    }

    
    
    //cudaFree(c_line_queries_array);
    cudaFree(c_reference);
    cudaFree(r_idxs);
    cudaFree(r_line_idx);
    cudaFree(r_pat_idx);
    cudaFree(r_query_idx);
    cudaFree(r_hits);
    cudaFree(r_extension_scores);

    cudaFree(idxs);
    cudaFree(line_idx);
    cudaFree(pat_idx);
    cudaFree(query_idx);
    cudaFree(hits);
    cudaFree(extension_scores);

}



__global__ void search(char *c_queries_flattened, int line_queries_used, 
            char *reference, 
            int k, 
            int ref_length,
            int *r_idxs,
            int *r_line_idx,
            int *r_pat_idx,
            int *r_query_idx,
            int *r_hits,
            int *r_extension_scores,
            int NUMBER_OF_CUDA_THREADS,
            int number_of_queries,
            int *idxs,
            int *line_idxs,
            int *pat_idxs,
            int *query_idxs,
            int *hits,
            int *extension_scores,
            int *hold_max_idx)
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
    

    char pat_text[MAX_READ_LENGTH];
    //cudaMalloc(&pat_text, MAX_READ_LENGTH*sizeof(char));
    //for (int line_idx=0; line_idx<line_queries_used; line_idx++){
    for (int l_idx=0; l_idx<batch_size; l_idx++){
        int s_idx=(l_idx+start_idx)*MAX_READ_LENGTH;
        
        //for(int i = y; i>0; i--) result *= x;
        for(int xx=0;xx<MAX_READ_LENGTH;xx++)
            pat_text[xx]=c_queries_flattened[s_idx+xx];

        //char *pat_text = copy_pattern(c_queries_flattened+s_idx, MAX_READ_LENGTH);
        //char *pat_text = c_queries_flattened[l_idx+start_idx];
        //char *pat;
        int pat_len = cuda_strlen(pat_text);

        for(int p_idx=0;p_idx<=pat_len-k;p_idx++){

            int query_idx = get_query_idx(pat_text+p_idx, k);

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
                    while((x<ref_length)&&(y<pat_len)&&reference[x]&&pat_text[y]&&reference[x]!='\n'&&pat_text[y]!='\n'){
                        //printf("ref%cpattern%c\n",reference[x],pat_text[y]);
                        if(reference[x] == pat_text[y])
                            extension_score++;
                        else break;
                        x++;y++;
                    }
                    x=idx-1,y=p_idx-1;

                    while((0<=x)&&(0<=y)&&reference[x]&&pat_text[y]&&reference[x]!='\n'&&pat_text[y]!='\n'){
                    //while((x<ref_length)&&(y<pat_len)&&reference[x]&&pat_text[y]){
                        if(reference[x] == pat_text[y])
                            extension_score++;
                        else break;
                        x--;y--;
                    }
                  
                    //(r, idx, query_idx, line_idx, pat_idx, extension_score)
                    updateResultDict_cuda(
                                        r_idxs,
                                        r_line_idx,
                                        r_pat_idx,
                                        //r_query_idx,
                                        r_hits,
                                        r_extension_scores,
                                        idx,  
                                        query_idx, 
                                        l_idx, 
                                        p_idx, 
                                        extension_score,
                                        tid,
                                        number_of_queries,
                                        hold_max_idx);

                }
            }
        }

    }
    //cudaFree(pat_text);
    __syncthreads();
    //cudaDeviceSynchronize();
    
    int idx=0, max=0;
    if(tid==0){
        for(int ii=0;ii<number_of_queries;ii++){
            max=0,idx=0;
            for(int jj=0;jj<NUMBER_OF_CUDA_THREADS;jj++){
                if (r_extension_scores[jj*number_of_queries +ii]>max){
                    max = r_extension_scores[jj*number_of_queries +ii];
                    idx = jj;
                }
            }
            if (r_hits[idx*number_of_queries+ii]>=hits[ii]){
                int query_idx = ii;//r_query_idx[idx][i]
                extension_scores[query_idx]=r_extension_scores[idx*number_of_queries+ii];
                idxs[query_idx]=r_idxs[idx*number_of_queries+ii];//idx;
                line_idxs[query_idx]=r_line_idx[idx*number_of_queries+ii];
                pat_idxs[query_idx]=r_pat_idx[idx*number_of_queries+ii];
                hits[query_idx]=r_hits[idx*number_of_queries+ii];
            }
        }
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
        int extension_score,
        int tid,
        int number_of_queries,int *hold_max_idx)
{   
    int _idx = tid*number_of_queries+query_idx;
    if(idx>hold_max_idx[_idx]&&idx>r_idxs[_idx]){
        r_hits[_idx]++;
        hold_max_idx[_idx] = idx;
        //if(tid==0&&query_idx==63) printf("idx:%d\n");
    }
        
    
    if(r_extension_scores[_idx]<extension_score){
        r_extension_scores[_idx]=extension_score;
        r_idxs[_idx]=idx;
        r_line_idx[_idx]=line_idx;
        r_pat_idx[_idx]=pat_idx;
    }
    
}