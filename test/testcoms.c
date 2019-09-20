
////////////////////////////////////////////////
// #includes
////////////////////////////////////////////////

#include <stdio.h>
#include "easypio.h"

////////////////////////////////////////////////
// Constants
////////////////////////////////////////////////

#define LOAD_PIN 23
#define DONE_PIN 24

// Test Case from Appendix A.1, B
int keysize = 16;

char key[keysize] = {0x2B, 0x7E, 0x15, 0x16, 0x28, 0xAE, 0xD2, 0xA6,
                0xAB, 0xF7, 0x15, 0x88, 0x09, 0xCF, 0x4F, 0x3C};

char plaintext[16] = {0x32, 0x43, 0xF6, 0xA8, 0x88, 0x5A, 0x30, 0x8D,
                      0x31, 0x31, 0x98, 0xA2, 0xE0, 0x37, 0x07, 0x34};

char ct[16] = {0x39, 0x25, 0x84, 0x1D, 0x02, 0xDC, 0x09, 0xFB,
               0xDC, 0x11, 0x85, 0x97, 0x19, 0x6A, 0x0B, 0x32};

/*
  // Another test case from Appendix C.1

  int keysize = 16;

  char key[keysize] = {0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07,
                  0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F};

  char plaintext[16] = {0x00, 0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77,
                        0x88, 0x99, 0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF};

  char ct[16] = {0x69, 0xC4, 0xE0, 0xD8, 0x6A, 0x7B, 0x04, 0x30,
                 0xD8, 0xCD, 0xB7, 0x80, 0x70, 0xB4, 0xC5, 0x5A};
*/

/*
  // 192-bit test case from Appendix C.2

  int keysize = 24;

  char key[keysize] = {0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07,
                  0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F,
                  0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17};

  char plaintext[16] = {0x00, 0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77,
                        0x88, 0x99, 0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF};

  char ct[16] = {0xDD, 0xA9, 0x7C, 0xA4, 0x86, 0x4C, 0xDF, 0xE0,
                 0x6E, 0xAF, 0x70, 0xA0, 0xEC, 0x0D, 0x71, 0x91};
*/

/*
  // 256-bit test case from Appendix C.3

  int keysize = 32;

  char key[keysize] = {0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07,
                  0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F,
                  0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17,
                  0x18, 0x19, 0x1A, 0x1B, 0x1C, 0x1D, 0x1E, 0x1F};

  char plaintext[16] = {0x00, 0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77,
                        0x88, 0x99, 0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF};

  char ct[16] = {0x8E, 0xA2, 0xB7, 0xCA, 0x51, 0x67, 0x45, 0xBF,
                 0xEA, 0xFC, 0x49, 0x90, 0x4B, 0x49, 0x60, 0x89};
*/


////////////////////////////////////////////////
// Function Prototypes
////////////////////////////////////////////////

void encrypt(char*, char*, char*);
void print16(char*);
void printall(char*, char*, char*);

////////////////////////////////////////////////
// Main
////////////////////////////////////////////////

void main(void) {
  char cyphertext[16];

  pioInit();
  spiInit(244000, 0);

  // Load and done pins
  pinMode(LOAD_PIN, OUTPUT);
  pinMode(DONE_PIN, INPUT);

  // hardware accelerated encryption
  encrypt(key, plaintext, cyphertext, keysize);
  printall(key, plaintext, cyphertext);
}

////////////////////////////////////////////////
// Functions
////////////////////////////////////////////////

void printall(char *key, char *plaintext, char *cyphertext, int keysize) {
  printf("Key:        ");  printK(key, keysize);
  printf("Plaintext:  ");  print16(plaintext);  printf("\n");
  printf("Ciphertext: ");  print16(cyphertext);
  printf("Expected:   ");  print16(ct);

  if(strcmp(cyphertext, ct) == 0) {
    printf("\nSuccess!\n");
  } else {
    printf("\nBummer.  Test failed\n");
  }
}

void encrypt(char *key, char *plaintext, char *cyphertext, int keysize) {
  int i;
  int ready;

  digitalWrite(LOAD_PIN, 1);

  for(i = 0; i < 16; i++) {
    spiSendReceive(plaintext[i]);
  }

  for(i = 0; i < keysize; i++) {
    spiSendReceive(key[i]);
  }

  digitalWrite(LOAD_PIN, 0);

  while (!digitalRead(DONE_PIN));

  for(i = 0; i < 16; i++) {
    cyphertext[i] = spiSendReceive(0);
  }
}

void printK(char *text, int keysize) {
  int i;

  for(i = 0; i < keysize; i++) {
    printf("%02x ",text[i]);
  }
  printf("\n");
}

void print16(char *text) {
  int i;

  for(i = 0; i < 16; i++) {
    printf("%02x ",text[i]);
  }
  printf("\n");
}


