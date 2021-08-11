NVCC=nvcc
CUDAFLAGS= -std=c++14 -I .
all: kmer-parallel kmer-serial kmer-brute

kmer-parallel: kmer-parallel.cu util.cu  
	$(NVCC) $(CUDAFLAGS)  -o kmer-parallel kmer-parallel.cu util.cu
kmer-serial: kmer-serial.cu util.cu  
	$(NVCC) $(CUDAFLAGS)  -o kmer-serial kmer-serial.cu util.cu
kmer-brute: kmer-brute.cu util.cu  
	$(NVCC) $(CUDAFLAGS)  -o kmer-brute kmer-brute.cu util.cu
clean:
	rm -rf kmer *.o
