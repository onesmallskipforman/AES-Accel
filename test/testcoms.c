//==============================================================================
// #includes
//==============================================================================

#include <stdio.h>
#include <string.h>
#include "EasyPIO.h"

//==============================================================================
// Constants
//==============================================================================

#define LOAD_PIN 23
#define DONE_PIN 24

// Test Case from Appendix A.1, B
char key_128[16] = {0x2B, 0x7E, 0x15, 0x16, 0x28, 0xAE, 0xD2, 0xA6,
                    0xAB, 0xF7, 0x15, 0x88, 0x09, 0xCF, 0x4F, 0x3C};
char plt_128[16] = {0x32, 0x43, 0xF6, 0xA8, 0x88, 0x5A, 0x30, 0x8D,
                    0x31, 0x31, 0x98, 0xA2, 0xE0, 0x37, 0x07, 0x34};
char cit_128[16] = {0x39, 0x25, 0x84, 0x1D, 0x02, 0xDC, 0x09, 0xFB,
                    0xDC, 0x11, 0x85, 0x97, 0x19, 0x6A, 0x0B, 0x32};
// Another test case from Appendix C.1
// char key_128[16] = {0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07,
//                     0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F};
// char plt_128[16] = {0x00, 0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77,
//                     0x88, 0x99, 0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF};
// char cit_128[16] = {0x69, 0xC4, 0xE0, 0xD8, 0x6A, 0x7B, 0x04, 0x30,
//                     0xD8, 0xCD, 0xB7, 0x80, 0x70, 0xB4, 0xC5, 0x5A};

// 192-bit test case from Appendix C.2
char key_192[24] = {0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07,
                    0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F,
                    0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17};
char plt_192[16] = {0x00, 0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77,
                    0x88, 0x99, 0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF};
char cit_192[16] = {0xDD, 0xA9, 0x7C, 0xA4, 0x86, 0x4C, 0xDF, 0xE0,
                    0x6E, 0xAF, 0x70, 0xA0, 0xEC, 0x0D, 0x71, 0x91};

// 256-bit test case from Appendix C.3
char key_256[32] = {0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07,
                    0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F,
                    0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17,
                    0x18, 0x19, 0x1A, 0x1B, 0x1C, 0x1D, 0x1E, 0x1F};
char plt_256[16] = {0x00, 0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77,
                    0x88, 0x99, 0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF};
char cit_256[16] = {0x8E, 0xA2, 0xB7, 0xCA, 0x51, 0x67, 0x45, 0xBF,
                    0xEA, 0xFC, 0x49, 0x90, 0x4B, 0x49, 0x60, 0x89};

//==============================================================================
// Function Prototypes
//==============================================================================

void aes(char*, char*, char*, int);
void printK(char*, int);
void printall(char*, char*, char*, int, char*, int);
void testinit(char*, char*, int, char*, int);

//==============================================================================
// Main
//==============================================================================

int main(void) {

  // 16 is 128, 24 is 192, 32 is 256
  int keysize = 16, inv = 0;
  char translated[16], expected[16], message[16], key[keysize];

  // initialize raspberry pi
  pioInit();
  spiInit(244000, 0);

  // Load and done pins
  pinMode(LOAD_PIN, OUTPUT);
  pinMode(DONE_PIN, INPUT);

  // prep messages and keys for encryption
  testinit(key, message, keysize, expected, inv);

  // hardware accelerated encryption
  aes(key, message, translated, keysize);
  printall(key, message, translated, keysize, expected, inv);

  return 0;
}

//==============================================================================
// Functions
//==============================================================================

void printall(char *key, char *message, char *translated, int keysize,
              char *expected, int inv) {
  if (inv == 0) {printf("%d-bit AES Encryption\n", keysize);}
  else          {printf("%d-bit AES Decryption\n", keysize);}

  printf("Key:        ");  printK(key, keysize);
  printf("Message:    ");  printK(message, 16);
  printf("Translated: ");  printK(translated, 16);
  printf("Expected:   ");  printK(expected, 16);

  if(strcmp(translated, expected) == 0) {
    printf("Success!\n");
  } else {
    printf("Bummer. Test failed.\n");
  }
}

void aes(char *key, char *message, char *translated, int keysize) {
  int i;
  int ready;

  digitalWrite(LOAD_PIN, 1);
  for(i = 0; i < 16; i++) {spiSendReceive(message[i]);}
  for(i = 0; i < keysize; i++) {spiSendReceive(key[i]);}
  digitalWrite(LOAD_PIN, 0);

  while (!digitalRead(DONE_PIN));

  for(i = 0; i < 16; i++) {translated[i] = spiSendReceive(0);}
}

void printK(char *text, int keysize) {
  int i;

  for(i = 0; i < keysize; i++) {printf("%02x ",text[i]);}
  printf("\n");
}

void testinit(char *key, char *message, int keysize, char *expected, int inv) {

  char *plt;
  char *cit;

  if (keysize == 16) {
    key = key_128;
    plt = plt_128;
    cit = cit_128;
  } else if (keysize == 24){
    key = key_192;
    plt = plt_192;
    cit = cit_192;
  } else {
    key = key_256;
    plt = plt_256;
    cit = cit_256;
  }

  if (inv == 0) {
    message = plt;
    expected = cit;
  } else {
    message = cit;
    expected = plt;
  }
}

// void print16(char *text) {
//   int i;

//   for(i = 0; i < 16; i++) {
//     printf("%02x ",text[i]);
//   }
//   printf("\n");
// }
