#include <stdio.h>

int main() {
  FILE *fp_in1, *fp_in2, *fp_out;
  char filename_in1[] = "normalized-5-3-23-data.TXT";  // Name of the first input file
  char filename_in2[] = "normalized-5-3-23-data - Copy.TXT";  // Name of the second input file
  char filename_out[] = "output.txt";  // Name of the output file
  float acc_x, acc_y, acc_z, pitch, yaw, roll;
  int count1 = 0, count2 = 0;

  // Open the input files for reading
  fp_in1 = fopen(filename_in1, "r");
  if (fp_in1 == NULL) {
    printf("Error: could not open file %s for reading.\n", filename_in1);
    return 1;
  }
  fp_in2 = fopen(filename_in2, "r");
  if (fp_in2 == NULL) {
    printf("Error: could not open file %s for reading.\n", filename_in2);
    return 1;
  }

  // Open the output file for writing
  fp_out = fopen(filename_out, "w");
  if (fp_out == NULL) {
    printf("Error: could not open file %s for writing.\n", filename_out);
    return 1;
  }

  // Read in the data from the input files and write it to the output file
  while (1) {
    // Read from the first input file every 5 lines
    if (count1 % 5 == 0 && fscanf(fp_in1, "%f,%f,%f,%f,%f,%f,", &acc_x, &acc_y, &acc_z, &pitch, &yaw, &roll) == 6) {
      fprintf(fp_out, "%.2f, %.2f, %.2f,", acc_x, acc_y, acc_z);
      count1 = 0;
    }
    count1++;

    // Read from the second input file every 26 lines
    if (count2 % 26 == 0 && fscanf(fp_in2, "%f,%f,%f,%f,%f,%f,", &acc_x, &acc_y, &acc_z, &pitch, &yaw, &roll) == 6) {
      fprintf(fp_out, "%.2f, %.2f, %.2f,", acc_x, acc_y, acc_z);
      count2 = 0;
    }
    count2++;

    // Break out of the loop if we've reached the end of both input files
    if (feof(fp_in1) && feof(fp_in2)) {
      break;
    }

    // Write a newline character to the output file every time we've printed a line from both input files
    if (count1 == 1 && count2 == 1) {
      fprintf(fp_out, "\n");
    }
  }

  // Close the files
  fclose(fp_in1);
  fclose(fp_in2);
  fclose(fp_out);

  printf("Data written to file %s.\n", filename_out);

  return 0;
}