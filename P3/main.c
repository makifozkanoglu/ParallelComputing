#include <omp.h>

#include <stdio.h>
#include <stdlib.h>
#include <limits.h>
#include <string.h>

int **matrix;

int main(int argc, char* argv[]){
    double start; 
    double end; 
    
    int n;
    int threads=16;
    //int matrix[n][n];
    if (argc>1){
        n = atoi(argv[1]);
        //threads=atoi(argv[1]);n = 10000;
    } else return 0;
    int rank = n;
    int c1, c2;
    int dependency_graph[n];
    memset(dependency_graph, 0, n*sizeof(int) );

    matrix = (int **)malloc(n * sizeof(int *));
    //#pragma omp parallel for shared( matrix)
    /*
    for (int i=0; i<n; i++)
         matrix[i] = (int *)malloc(n * sizeof(int)); 
    */
    //#pragma omp parallel for shared(matrix)
    for (int i=0;i<n;i++){
        matrix[i] = (int *)malloc(n * sizeof(int)); 
        for (int j=0;j<n;j++){
            //matrix[i][j]=(int)malloc( sizeof(int)); 
            matrix[i][j]=rand()%(INT_MAX/8);
        }
    }
    //#pragma omp parallel for shared( matrix)
    for (int i=n-2;i<n;i++){
        //printf("%d\n",i);
        for (int j=0;j<n;j++){
            matrix[i][j]=2*matrix[i-1][j];
        }
    }
    
    start = omp_get_wtime(); 
    omp_set_num_threads(threads);
    #pragma omp parallel shared(rank, matrix, dependency_graph) private(c1,c2)
    {
    #pragma omp for ordered//collapse(2)
    for (int i=0;i<n;i++){
        if (dependency_graph[i]==0)
            for (int j=i+1;j<n;j++){ 
                //printf("%d %d %d\n", i, j, omp_get_thread_num());
                //#pragma omp single nowait
                if (dependency_graph[j]==0){
                    c1=matrix[i][0], c2=matrix[j][0];
                    int dependent=1;
                    for(int k=0;k<n;k++){
                        int diff= matrix[i][k]*c2 - matrix[j][k]*c1;
                        /*
                        if (i==9998 && j==9999){
                            printf("%d %d %d %d\n", i, j, k, omp_get_thread_num());
                            //printf("%d %d %d %d %d %d %d\n", matrix[i][k], matrix[j][k], matrix[i][k]*c2, matrix[j][k]*c1, c1,c2,diff);
                        }
                        */
                        if (diff!=0){
                            dependent = 0;
                            break;
                        }                      
                    }
                    if (dependent){
                        dependency_graph[j]=1;
                        //printf("%d %d %d\n", i, j, omp_get_thread_num());
                        #pragma omp atomic
                        rank--;
                    }
                }
            }
    }
    }
    //#pragma omp barrier
    end = omp_get_wtime(); 
    printf("Parallel rank:%d\n",rank);
    printf("Work took %f seconds\n", end - start);
    
    /*
    rank = n;
    start = omp_get_wtime(); 
    for (int i=0;i<n;i++){
        for (int j=i+1;j<n;j++){
             //{
                c1=matrix[i][0], c2=matrix[j][0];
                int dependent=1;
                for(int k=0;k<n;k++){
                    if ((matrix[i][k]*c2 - matrix[j][k]*c1)!=0){
                        dependent = 0;
                        break;
                    }
                }

                
                if (dependent){
                    rank--;
                }
            //}
        }
    }
    end = omp_get_wtime(); 
    printf("Serial rank:%d\n",rank);
    printf("Work took %f seconds\n", end - start);
    */
}

