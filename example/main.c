#include <stdio.h>
#include <time.h>

#include "cmake/build.h"

#define QUOTE_EX(x) #x
#define QUOTE(x)    QUOTE_EX(x)

int main( int argc, char *argv[] )
{
    const time_t config_tmstmp = CONFIG_TIMESTAMP;
    const time_t build_tmstmp = BUILD_TIMESTAMP;

    const char ver_str[] = QUOTE(VERSION_MAJOR)"."QUOTE(VERSION_MINOR)"."QUOTE(VERSION_PATCH);

    printf("Build Version : %s\n", ver_str);

    char buff[20];

    strftime(buff, 20, "%d-%m-%Y %H:%M:%S", localtime(&config_tmstmp));
    printf("Config Time : %s\n", buff);

    strftime(buff, 20, "%d-%m-%Y %H:%M:%S", localtime(&build_tmstmp));
    printf("Build Time : %s\n", buff);

    return 0;
}