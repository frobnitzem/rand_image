#include <iostream>
#include <stdlib.h>

#include <Random123/philox.h>

#define WIDTH 64

using CBRNG = r123::Philox4x32;

unsigned int *gen_image_cpu(unsigned dim, unsigned int seed) {
    CBRNG::key_type key = {{seed}};
    CBRNG::ctr_type ctr = {{0,0}};
    CBRNG g;

    unsigned int *image = (unsigned int *)malloc(dim*dim*sizeof(unsigned int));
    for(int x = 0; x < dim; x++) {
        for(int y = 0; y < dim; y++) {
            unsigned int id = x*dim+y;
            ctr[0] = 0;
            ctr[1] = id;
            CBRNG::ctr_type rand = g(ctr, key);
            image[id] = rand[0];
        }
    }
    return image;
}

int main(int argc, char *argv[]) {
    if(argc != 3) {
        std::cout << "Usage: " << argv[0] << " <dim> <steps>\n";
        return 1;
    }
    int dim = atoi(argv[1]);
    int steps = atoi(argv[2]);

    unsigned int *img = gen_image_cpu(100, steps);

    for(int i=0; i<dim; i += dim/10) {
        uint32_t id = i*dim + i;
        std::cout << i << ": " << img[id] << " " << img[id+1] << std::endl;
    }

    free(img);
    return 0;
}
