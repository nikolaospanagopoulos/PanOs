./bin/os: ./bin/boot.bin  ./bin/secBootloader.bin ./bin/kernel.bin
	cat ./bin/boot.bin ./bin/secBootloader.bin ./bin/kernel.bin > ./bin/os.bin
	dd if=/dev/zero of=OS.bin bs=512 count=2880;
	dd if=./bin/os.bin of=OS.bin conv=notrunc;
./bin/boot.bin:
	fasm ./boot.asm  ./bin/boot.bin
./bin/secBootloader.bin:
	fasm ./secBootloader.asm ./bin/secBootloader.bin
./bin/kernel.bin:
	fasm ./kernel.asm ./bin/kernel.bin
clean:
	rm ./bin/*.bin
