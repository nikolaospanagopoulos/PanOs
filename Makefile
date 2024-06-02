./bin/os: ./bin/boot.bin  ./bin/secBootloader.bin ./bin/kernel.bin
	cat ./bin/boot.bin ./bin/secBootloader.bin ./bin/kernel.bin > ./bin/os.bin
./bin/boot.bin:
	fasm ./boot.asm  ./bin/boot.bin
./bin/secBootloader.bin:
	fasm ./secBootloader.asm ./bin/secBootloader.bin
./bin/kernel.bin:
	fasm ./kernel.asm ./bin/kernel.bin
clean:
	rm ./bin/*.bin
