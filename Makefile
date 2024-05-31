./bin/os: ./bin/boot.bin ./bin/kernel.bin
	cat ./bin/boot.bin ./bin/kernel.bin > ./bin/os.bin
./bin/boot.bin:
	fasm ./boot.asm  ./bin/boot.bin
./bin/kernel.bin:
	fasm ./kernel.asm ./bin/kernel.bin
clean:
	rm ./bin/*.bin
