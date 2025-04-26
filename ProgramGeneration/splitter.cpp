/*
This program converts hexadecimal machine code into byte-addressable lines of memory. Good if using an online assembler.
*/

#include <iostream>
#include <fstream>
#include <sstream>
#include <string>
#include <cctype>
#include <cstdio>
#include <bitset>

unsigned long long hexToDecimal(const std::string& hexStr) {
    return std::stoull(hexStr, nullptr, 16);
}

int main() {
    const std::string inputFilename = "input.txt";
    const std::string outputFilename = "output.txt";

    std::ifstream inputFile(inputFilename);
    FILE* outputFile = std::fopen(outputFilename.c_str(), "w");

    if (!inputFile) {
        std::cerr << "Error: Cannot open input file '" << inputFilename << "'\n";
        return 1;
    }

    if (!outputFile) {
        std::cerr << "Error: Cannot open output file '" << outputFilename << "'\n";
        return 1;
    }

    std::string line;
    while (std::getline(inputFile, line)) {
        if (line.empty()) continue;

        try {
            unsigned long long decimalValue = hexToDecimal(line);
            int line7_0 = decimalValue & 0xFF;
            int line15_8 = (decimalValue>>8) & 0xFF;
            int line23_16 = (decimalValue>>16) & 0xFF;
            int line31_24 = (decimalValue>>24) & 0xFF;
            std::fprintf(outputFile, "%02X\n", line7_0); 
            std::fprintf(outputFile, "%02X\n", line15_8); 
            std::fprintf(outputFile, "%02X\n", line23_16); 
            std::fprintf(outputFile, "%02X\n", line31_24); 
        } catch (const std::exception& e) {
            std::cerr << "Invalid binary string: " << line << "\n";
        }
    }

    inputFile.close();
    std::fclose(outputFile);

    std::cout << "Conversion complete.\n";
    return 0;
}
