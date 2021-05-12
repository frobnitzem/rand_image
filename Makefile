all: main_cpu main_gpu

main_gpu: main.cu
	nvcc -o main_gpu main.cu 

main_cpu: main.cc
	g++ -o main_cpu -I Random123-1.13.2/include main.cc
