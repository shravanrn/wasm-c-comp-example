#include "greeter.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void exports_wasmcon2023_greet_interface_greet(greeter_string_t *ret) {
    char* suffix = "<ENDPOINT>";
    size_t suffix_len = strlen(suffix);

    ret->len = suffix_len;
    ret->ptr = malloc(ret->len);

    memcpy(ret->ptr, suffix, suffix_len);
}

