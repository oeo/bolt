# custom hash function: rust implementation

## overview
This custom hash function is designed with the aim of balancing computational
efficiency across different hardware architectures, specifically between CPUs 
and GPUs. It leverages the Blake2b512 hashing algorithm and incorporates several
strategies to ensure that the function is memory-hard, benefits from sequential
processing, and presents a balanced workload that can be processed efficiently
on both CPU and GPU architectures.

## goals

1. **democratize mining:** By balancing efficiency between CPUs and GPUs, this hashing function aims to make mining more accessible to individuals without specialized hardware, potentially leading to a more decentralized and democratic mining landscape.
1. **memory-hardness:** The function is designed to be memory-hard, meaning it requires a significant amount of memory bandwidth, which GPUs do not necessarily optimize for, thus leveling the playing field with CPUs.
1. **sequential processing:** Through the inclusion of sequential dependencies that prevent parallel processing, the function aims to mitigate the inherent parallel computation advantage of GPUs over CPUs.
1. **adaptability:** The function uses dynamic memory allocation and hashing iterations based on the input, making it more resistant to optimization and pre-computation attacks.

## implementation details

- **Blake2b512:** The core hashing algorithm used is `Blake2b512`, known for its speed and security.
- **seed generation:** The seed for the random number generator (RNG) is derived from the first 32 bytes of the input's Blake2b512 hash, ensuring that each input produces a unique memory pattern and computation path.
- **dynamic memory allocation:** The function dynamically allocates a memory buffer based on RNG, making the memory usage unpredictable and enhancing memory-hardness.
- **sequential dependencies:** The algorithm performs 1000 sequential Blake2b512 hash computations, each dependent on the result of the previous computation, to introduce a significant sequential processing component.
- **final hash calculation:** The final hash is produced.

