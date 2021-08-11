#include <util.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <sys/wait.h> 

/*
int check_pattern(const char* pat, const char* txt, int ref_length, int k, int *idx)
{
    //int M = strlen(pat);
    //int N = strlen(txt);
 
    // A loop to slide pat[] one by one 
    for (int i = 0; i <= ref_length - k; i++) {
        int j;
 
        // For current index i, check for pattern match 
        for (j = 0; j < k; j++)
            if (txt[i + j] != pat[j])
                break;
 
        if (j == k){ // if pat[0...k-1] = txt[i, i+1, ...i+k-1]
            printf("Pattern found at index %d \n", i);
            *idx=i;
            return 1;
        }
    }
    return -1;
}
*/
int get_query_idx(char *query, int k){
    const char cs[4]={'A','T','G','C'};
    int idx=0;
    int i=0;
    int count=0;
    //printf("wwwwwwwwwww\n");
    for(i=0;i<k;i++){
        int coeff = ipow(4,k-i-1);
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
void search(StringList *line_queries, char *reference, int k, 
            int ref_length, ResultDict *r
            /*, char **idx_ptr, int *idx*/){
    //int idx;
    /*int query_size = ipow(4,k);
    int query_not_exist[query_size];
    for (int i=0;i<query_size;i++)
        query_not_exist[i]=0;*/
    
    int *hold_max_idx=(int *)malloc(r->size*sizeof(int));
    for (int vv=0;vv<r->size;vv++)
        hold_max_idx[0]=-1;

    for (int line_idx=0; line_idx<line_queries->used; line_idx++){
        char *pat_text = line_queries->array[line_idx];
        //char *pat;
        int pat_len = strlen(pat_text);
        //printf("%s, %d\n",pat_text, pat_len);
        //printf("line idx=%d, %s \n", line_idx,pat_text);
        for(int pat_idx=0;pat_idx<pat_len-k;pat_idx++){
            //printf("********************************\n");
            int query_idx = get_query_idx(pat_text+pat_idx, k);


            for (int idx = 0; idx <= ref_length - k; idx++) {
                int l;/*
        
                /* For current index idx, check for pattern match */
                for (l = 0; l < k; l++)
                    if (reference[idx + l] != pat_text[pat_idx+l])
                        break;
        
                if (l == k){ // if pat[0...k-1] = txt[idx, idx+1, ...idx+k-1]
                    int x=idx+k,y=pat_idx+k;
                    int extension_score=k;
                    //while((0<=x)&&(0<=y)&&reference[x]&&pat_text[y]){
                    while((x<ref_length)&&(y<pat_len)&&reference[x]&&pat_text[y]&&reference[x]!='\n'&&pat_text[y]!='\n'){
                        //printf("ref%cpattern%c\n",reference[x],pat_text[y]);
                        if(reference[x] == pat_text[y]&&reference[x]!='\n' )
                            extension_score++;
                        else break;
                        x++;y++;
                    }
                    x=idx-1,y=pat_idx-1;

                    while((0<=x)&&(0<=y)&&reference[x]&&pat_text[y]&&reference[x]!='\n'&&pat_text[y]!='\n'){
                    //while((x<ref_length)&&(y<pat_len)&&reference[x]&&pat_text[y]){
                        if(reference[x] == pat_text[y] )
                            extension_score++;
                        else break;
                        x--;y--;
                    }
                    // calculate query idx and extension score
                    updateResultDict(r, idx, query_idx, line_idx, pat_idx, extension_score, hold_max_idx);

                }
            }
        }

    }

}



int main(int argc, char** argv)
{
    if(argc != 5) {
        printf("Wrong argments usage: ./kmer [REFERENCE_FILE] [READ_FILE] [k] [OUTPUT_FILE]\n" );
    }

    clock_t start = clock(), diff;
    FILE *fp;
    int k;

    //malloc instead of allocating in stack
    char *reference_str = (char*) malloc(MAX_REF_LENGTH * sizeof(char));
    char *read_str = (char*) malloc(MAX_READ_LENGTH * sizeof(char));

    char *reference_filename, *read_filename, *output_filename;
    int reference_length;
    
    reference_filename = argv[1];
    read_filename = argv[2];
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
    //for (int i=0;i<queries.used;i++)//{
    //   printf("Reference str is = %s for %d idx\n", queries.array[i],i);
    //}
      
    reference_length = strlen(reference_str); //Last character is '\n'
    
    ResultDict result;
    initResultDict(&result, k);
    
    search(&queries, reference_str, k, reference_length, &result);

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

}
