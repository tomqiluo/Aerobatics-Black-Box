// gcc kml2fdr.c -o kml2fdr
// ./kml2fdr Flight2_5-3-2023.kml output.fdr

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

void parse_coordinates(FILE *output, const char *coord_str, int count) {
    double lon, lat, alt;
    const char *token = coord_str;
    char *end;

    while (*token) {
        while (isspace((unsigned char)*token)) {
            token++; // Skip whitespaces
        }

        lon = strtod(token, &end);
        token = (*end == ',') ? end + 1 : end;
        lat = strtod(token, &end);
        token = (*end == ',') ? end + 1 : end;
        alt = strtod(token, &end);
        token = (*end == ' ') ? end + 1 : end;
        if (count%5 == 0) {
            if (lon != 0.0 || lat != 0.0 || alt != 0.0) {
                fprintf(output, "DATA,%d,%lf,%lf,%lf\n", count, lon, lat, alt);
            }
        }
        
    }
}

int main(int argc, char **argv) {
    if (argc != 3) {
        printf("Usage: %s <kml_file> <output>\n", argv[0]);
        return 1;
    }

    FILE *input = fopen(argv[1], "r");
    if (input == NULL) {
        printf("Failed to open %s\n", argv[1]);
        return 1;
    }

    FILE *output = fopen(argv[2], "w");
    if (output == NULL) {
        printf("Failed to open %s\n", argv[2]);
        fclose(input);
        return 1;
    }

    fprintf(output, "A\n3\nThis is the needed beginning of the file: 'A' or 'I' for 'Apple' or 'IBM' carriage-returns, followed by an IMMEDIATE carriage return, followed by the version number of 3\n\n");


    const size_t buf_size = 4096;
    char line[buf_size];
    int inside_coordinates = 0;

    int count = 0;
    while (fgets(line, buf_size, input)) {
        if (!inside_coordinates && strstr(line, "<coordinates>")) {
            inside_coordinates = 1;
        } else if (inside_coordinates && strstr(line, "</coordinates>")) {
            inside_coordinates = 0;
        } else if (inside_coordinates) {
            parse_coordinates(output, line, count);
            count = count + 1;
        }
    }

    fclose(input);
    fclose(output);
    return 0;
}