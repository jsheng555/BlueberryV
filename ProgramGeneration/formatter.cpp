/*
This program converts machine code with whitespace to lines of hex that can be loaded into program memory.
*/

#include <iostream>
#include <fstream>
#include <sstream>
#include <string>
#include <cctype>
#include <cstdio>
#include <bitset>

std::string removeWhitespace(const std::string& str) {
    std::string result;
    for (char c : str) {
        if (!std::isspace(static_cast<unsigned char>(c))) {
            result += c;
        }
        if (c == ';') return result;
    }
    return result;
}

unsigned long long binaryToDecimal(const std::string& binaryStr) {
    return std::stoull(binaryStr, nullptr, 2);
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
        std::string binaryStr = removeWhitespace(line);
        if (binaryStr.empty()) continue;

        try {
            unsigned long long decimalValue = binaryToDecimal(binaryStr);
            int line7_0 = decimalValue & 0xFF;
            int line15_8 = (decimalValue>>8) & 0xFF;
            int line23_16 = (decimalValue>>16) & 0xFF;
            int line31_24 = (decimalValue>>24) & 0xFF;
            std::fprintf(outputFile, "%02X\n", line7_0); 
            std::fprintf(outputFile, "%02X\n", line15_8); 
            std::fprintf(outputFile, "%02X\n", line23_16); 
            std::fprintf(outputFile, "%02X\n", line31_24); 
        } catch (const std::exception& e) {
            std::cerr << "Invalid binary string: " << binaryStr << "\n";
        }
    }

    inputFile.close();
    std::fclose(outputFile);

    std::cout << "Conversion complete.\n";
    return 0;
}
