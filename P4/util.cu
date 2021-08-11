#include "util.h"

int ipow(int x,int y){

    int result = 1;

    //for(int i = y; i>0; i--) result *= x;
    while (y != 0) {
        result *= x;
        --y;
    }
    return result;
}



void initResultDict(ResultDict *a, size_t k){
    int initialSize = ipow(4,(int)k);

    a->idxs = (int*) malloc(initialSize * sizeof(int));
    a->line_idx = (int*) malloc(initialSize * sizeof(int));
    a->pat_idx = (int*) malloc(initialSize * sizeof(int));
    a->query_idx = (int*) malloc(initialSize * sizeof(int));
    a->hits = (int*) malloc(initialSize * sizeof(int));
    a->extension_scores = (int*) malloc(initialSize * sizeof(int));

    int perms=ipow(4,(int)k);
    //char gens[perms][k];
    const char cs[4]={'A','T','G','C'};

    a->queries=(char **)malloc(perms*sizeof(char *));
    for (int i=0;i<initialSize;i++){
        a->line_idx[i]=0;
        a->line_idx[i]=0;
        a->pat_idx[i]=0;

        a->query_idx[i]=i;

        a->hits[i]=1;
        a->extension_scores[i]=0;
        int j;
        a->queries[i]=(char *)malloc(k*sizeof(char));
        for (j=0;j<k;j++){
            //int count=i*k+j;x
            int x=(int)ipow(4,k-j);
            a->queries[i][j]=cs[(i%x)/(x/4)];
        }
        a->queries[i][j]='\0';
    }
    //a->queries = &gens;
    //a->used = 0;
    a->size = initialSize;
}


void updateResultDict(ResultDict *a,int idx, int query_idx, int line_idx,int pat_idx, int extension_score, int *hold_max_idx){
    if(idx>hold_max_idx[query_idx]&&idx>(a->idxs[query_idx])){
        a->hits[query_idx]++;
        hold_max_idx[query_idx] = idx;
        //if(tid==0&&query_idx==63) printf("idx:%d\n");
    }
    if(a->extension_scores[query_idx]<extension_score){
        a->extension_scores[query_idx]=extension_score;
        a->idxs[query_idx]=idx;
        a->line_idx[query_idx]=line_idx;
        a->pat_idx[query_idx]=pat_idx;
    }
}

void freeResultDict(ResultDict *a){
    free(a->idxs);
    free(a->line_idx);
    free(a->pat_idx);
    free(a->query_idx);
    free(a->hits);
    free(a->extension_scores);
    a->idxs = NULL;
    a->line_idx = NULL;
    a->pat_idx = NULL;
    a->query_idx = NULL;
    a->hits = NULL;
    a->extension_scores = NULL;
    //a->used = a->size = 0;
    a->size = 0;
}

void initStringList(StringList *a, size_t initialSize) {
    a->array = (char**) malloc(initialSize * sizeof(char*));
    for (int i = 0; i < initialSize; i++) {
        a->array[i] = (char*) malloc(MAX_READ_LENGTH * sizeof(char));
    }
    a->used = 0;
    a->size = initialSize;
}

void insertStringList(StringList *a, char *element) {
    // a->used is the number of used entries, because a->array[a->used++] updates a->used only *after* the array has been accessed.
    // Therefore a->used can go up to a->size
    if (a->used == a->size) {
        a->size *= 2;
        a->array = (char**) realloc(a->array, a->size * sizeof(char*));
        for (int i = (a->size)/2; i < a->size; i++) {
            a->array[i] = (char*) malloc(MAX_READ_LENGTH * sizeof(char));
        }
    }
    strcpy(a->array[a->used++], element);
}

void freeStringList(StringList *a) {
    for(int i = 0; i < a->size; i++) {
        free(a->array[i]);
    }
    free(a->array);
    a->array = NULL;
    a->used = a->size = 0;
}

int read_file(char *file_name, StringList *sequences) {
    FILE *fp;
    fp = fopen(file_name, "r");
    if(fp) {
        char *line = (char *) malloc( MAX_READ_LENGTH * sizeof(char));
        while (fgets(line, MAX_READ_LENGTH, fp) != NULL) { //A single line only
            //printf("%s", line);
            insertStringList(sequences,line);
        }
        free(line);
        fclose(fp);
        return 0;
    }
    return -1; //Means error
}

//Do not use substring methods for cuda kernel, try a more primitive approach
//without memory operations for performance
void substring(char *source, int begin_index, int end_index)
{
    // copy n characters from source string starting from
    // beg index into destination
    memmove(source, (source + begin_index), end_index-begin_index);
    source[end_index-begin_index] = '\0';
}

void substring(char *destination, char *source, int begin_index, int end_index)
{
    // copy n characters from source string starting from
    // beg index into destination
    memcpy(destination, (source + begin_index), end_index-begin_index);
    destination[end_index-begin_index] = '\0';
}

/*
* You might use these for some simple string operations in GPU
* Put these code into your program

__device__ int cuda_strlen(const char* string){
    int length = 0;
    while (*string++)
        length++;

    return (length);
}

//Compares string until nth character
__device__ int d_strncmp( const char * s1, const char * s2, size_t n )
{
    while ( n && *s1 && ( *s1 == *s2 ) )
    {
        ++s1;
        ++s2;
        --n;
    }
    if ( n == 0 )
    {
        return 0;
    }
    else
    {
        return ( *(unsigned char *)s1 - *(unsigned char *)s2 );
    }
}
*/
