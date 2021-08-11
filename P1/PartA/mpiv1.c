#include <stdio.h>
#include <stdlib.h>
#include <mpi.h>

int main(int argc, char *argv[]) {
    // Master tasks.
    double timeStart, timeEnd;
    FILE *in_txt;
    char *provided_path = argv[1];
    char *filepath;
    int arr[255];
    int index;
    int global_min = (int) INT16_MAX; 
    int curr_val = 0;
    int len = 0;    // No. of items on given input.

    asprintf(&filepath, "%s%s", provided_path, ".txt");
    in_txt = fopen(filepath, "r");
    if (in_txt == NULL) {
        printf("File can\'t be read!\n");
        fclose(in_txt);
        exit(0);
    }

    for (len = 0; fscanf(in_txt, "%d\n", &curr_val) != EOF; len++) {
        arr[len] = curr_val;
    }
    fclose(in_txt);

    timeStart = MPI_Wtime();
    // Splitting.
    MPI_Status s;
    int size, rank, i, local_min;
    MPI_Init(&argc, &argv);
    MPI_Comm_size(MPI_COMM_WORLD, &size);   // Size is no. of processes.  # size = 6
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    if (rank != 0) {   // Child process.
        int start, end;
        if (rank == size - 1){ // Last process.
            start = ((size-2) * len / (size - 1));
            end = len - 1; // get whatever is remaining.
        } else{
            start = (rank - 1) * len / (size - 1);
            end = (rank) * len / (size - 1) - 1;
        }
        local_min = (int) INT16_MAX; // Calculate the local min here.
        for (index = start; index <= end; index++){
            if(arr[index] < local_min){
                local_min = arr[index];
            }
        }
        MPI_Send((void *) &local_min, 1, MPI_INT, 0, 0xACE5, MPI_COMM_WORLD);
        MPI_Barrier(MPI_COMM_WORLD);
    } else {    // Master process.
        printf("Receiving data . . .\n");
        for (i = 1; i < size; i++) {
            MPI_Recv((void *) &local_min, 1, MPI_INT, i, 0xACE5, MPI_COMM_WORLD, &s);
            printf("[%d] sent %d as local min.\n", i, local_min);
            if (local_min < global_min){
                global_min = local_min;
            }
        }
        MPI_Barrier(MPI_COMM_WORLD);
        timeEnd = MPI_Wtime();
        printf("min-mpi-v1: Global min data is %d.\n", global_min);
        printf("Running time = %f seconds.\n", timeEnd - timeStart);
    }
    MPI_Finalize();
    return 0;
}