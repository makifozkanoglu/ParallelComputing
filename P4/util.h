//TODO this length is not enough, it should be something like a million
#define MAX_READ_LENGTH 200
#define MAX_REF_LENGTH 2000000

#include <stdlib.h>
#include <stdio.h>
#include <string.h>

/**
 * usage:
   StringList a;
   char* sample1 = "example1";
   char* sample2 = "example2";
   char* sample3 = "example3";

   initStringList(&a, 2);  // initially 5 elements
   insertStringList(&a, sample1);  // automatically resizes as necessary
   insertStringList(&a, sample2);  // automatically resizes as necessary
   insertStringList(&a, sample3);  // automatically resizes as necessary
   printf("%s\n", a.array[9]);  // print 10th element
   printf("%d\n", a.used);  // print number of elements
   freeStringList(&a);
 *
 */
typedef struct {
    char **array;
    int used;
    int size;
} StringList;

typedef struct {
    int *idxs;
    int *line_idx;
    int *pat_idx;
    int *query_idx;
    char **queries;
    int *hits;
    int *extension_scores;
    //size_t used;
    int size;
} ResultDict;

void initResultDict(ResultDict *a, size_t initialSize);
//void insertResultList(ResultList *a, int element);
void freeResultDict(ResultDict *a);
void updateResultDict(ResultDict *a,int idx, int query_idx, int line_idx,int pat_idx, int extension_score, int * hold_max_idx);


void initStringList(StringList *a, size_t initialSize);

void insertStringList(StringList *a, char *element);

void freeStringList(StringList *a);


int read_file(char *file_name, StringList *sequences);

void substring(char *source, int begin_index, int end_index);

void substring(char *destination, char *source, int begin_index, int end_index);

//__device__ int cuda_strlen(const char* string);

//__device__ int d_strncmp( const char * s1, const char * s2, size_t n );

int ipow(int x,int y);

//__device__ int ipow_cuda(int x,int y);