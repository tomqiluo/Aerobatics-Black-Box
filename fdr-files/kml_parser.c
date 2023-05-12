// gcc kml_parser.c -o kml_parser
// kml_parser Flight2_5-3-2023.kml

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

void parse_coordinates(const char *coord_str) {
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

        if (lon != 0.0 || lat != 0.0 || alt != 0.0) {
            printf("Longitude: %lf, Latitude: %lf, Altitude: %lf\n", lon, lat, alt);
        }
    }
}

int main(int argc, char **argv) {
    if (argc != 2) {
        printf("Usage: %s <kml_file>\n", argv[0]);
        return 1;
    }

    FILE *file = fopen(argv[1], "r");
    if (file == NULL) {
        printf("Failed to open %s\n", argv[1]);
        return 1;
    }

    const size_t buf_size = 4096;
    char line[buf_size];
    int inside_coordinates = 0;

    while (fgets(line, buf_size, file)) {
        if (!inside_coordinates && strstr(line, "<coordinates>")) {
            inside_coordinates = 1;
        } else if (inside_coordinates && strstr(line, "</coordinates>")) {
            inside_coordinates = 0;
        } else if (inside_coordinates) {
            parse_coordinates(line);
        }
    }

    fclose(file);
    return 0;
}