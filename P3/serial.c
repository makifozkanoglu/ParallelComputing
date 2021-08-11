#include <time.h>

#include <stdio.h>
#include <stdlib.h>
#include <limits.h>
#include <string.h>



int **matrix;

int main(int argc, char* argv[]){
    clock_t start; 
    clock_t t; 

    int n;
    if (argc>1){
        n = atoi(argv[1]);
    } else return 0;
    
    //int matrix[n][n];
    int rank = n;
    int c1, c2;
    int dependency_graph[n];
    memset(dependency_graph, 0, n*sizeof(int) );
    //#pragma omp parallel shared(matrix)

    matrix = (int **)malloc(n * sizeof(int *));
    for (int i=0;i<n;i++){
        matrix[i] = (int *)malloc(n * sizeof(int)); 
        for (int j=0;j<n;j++){
            //matrix[i][j]=(int)malloc( sizeof(int)); 
            matrix[i][j]=rand()%(INT_MAX/8);
        }
    }
    for (int i=n-2;i<n;i++){
        //printf("%d\n",i);
        for (int j=0;j<n;j++){
            matrix[i][j]=2*matrix[i-1][j];
        }
    }

    //start = omp_get_wtime(); 
    start = clock();
    for (int i=0;i<n;i++){
        if (dependency_graph[i]==0)
            for (int j=i+1;j<n;j++){
                //{
                    if (dependency_graph[j]==0)
                        
                        c1=matrix[i][0], c2=matrix[j][0];
                        int dependent=1;
                        for(int k=0;k<n;k++){
                            if ((matrix[i][k]*c2 - matrix[j][k]*c1)!=0){
                                dependent = 0;
                                break;
                            }
                        }

                        
                        if (dependent){
                            dependency_graph[j]=1;
                            rank--;
                        }
                //}
            }
    }
    //end = omp_get_wtime(); 
    printf("Serial rank:%d\n",rank);
    t = clock() - start;
    double time_taken = ((double)t)/CLOCKS_PER_SEC;
    printf("Work took %f seconds\n", time_taken);
    
}

