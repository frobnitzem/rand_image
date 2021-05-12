#include <iostream>
#include <stdlib.h>

#include <cuda.h>
#include <curand_kernel.h>

#define WIDTH 64

using crngState = curandStatePhilox4_32_10_t;

/* Each thread gets same seed, a different sequence
   number, no offset */
__global__ void setup_curand(crngState *state, unsigned long seed, unsigned dim) {
    uint32_t xid = blockIdx.z * blockDim.x + threadIdx.x;
    uint32_t id  = blockIdx.y*dim + xid;
    if(xid >= dim) return;

    //printf("blocks: %d %d %d / %d %d %d\n", blockIdx.x, blockIdx.y, blockIdx.z, gridDim.x, gridDim.y, gridDim.z);
    //printf("threads: %d %d %d / %d %d %d\n", threadIdx.x, threadIdx.y, threadIdx.z, blockDim.x, blockDim.y, blockDim.z);
    curand_init(seed, id, 0, &state[id]);
}

__global__ void gen_image_kernel(crngState *state, unsigned int *result, unsigned dim) {
    uint32_t xid = blockIdx.z * blockDim.x + threadIdx.x;
    uint32_t id  = blockIdx.y*dim + xid;
    if(xid >= dim) return;

    crngState localState = state[id];
    unsigned int x = curand(&localState);
    state[id] = localState;
    result[id] = x;
}

unsigned int *gen_image_gpu(unsigned dim, unsigned int seed) {
    unsigned int *image = (unsigned int *)malloc(dim*dim*sizeof(unsigned int));
    unsigned int *image_d;
    crngState *state;
    
    cudaMalloc(&image_d, dim*dim*sizeof(unsigned int));
    dim3 dims(1, dim, (dim+WIDTH-1)/WIDTH);
    
    cudaMalloc(&state, WIDTH*sizeof(crngState));
    setup_curand<<< dims, WIDTH >>>(state, seed, dim);
    gen_image_kernel<<< dims, WIDTH >>>(state, image_d, dim);
    cudaMemcpy(image, image_d, dim*dim*sizeof(unsigned int), cudaMemcpyDeviceToHost);
    cudaFree(state);
    cudaFree(image_d);

    return image;
}

int main(int argc, char *argv[]) {
    if(argc != 3) {
        std::cout << "Usage: " << argv[0] << " <dim> <steps>\n";
        return 1;
    }
    int dim = atoi(argv[1]);
    int steps = atoi(argv[2]);

    unsigned int *img = gen_image_gpu(dim, steps);

    for(int i=0; i<dim; i += (dim+9)/10) {
        uint32_t id = i*dim + i;
        std::cout << i << ": " << img[id] << " " << img[id+1] << std::endl;
    }

    free(img);
    return 0;
}
