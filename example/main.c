#include <stdio.h>
#include <time.h>

#include "cmake/build.h"

#define QUOTE_EX(x) #x
#define QUOTE(x)    QUOTE_EX(x)

int main( int argc, char *argv[] )
{
    static const time_t config_tmstmp = EXPL_CONFIG_TIMESTAMP;
    static const time_t build_tmstmp = EXPL_BUILD_TIMESTAMP;

    static const char ver_str[] = QUOTE(EXPL_VERSION_MAJOR)"."QUOTE(EXPL_VERSION_MINOR)"."QUOTE(EXPL_VERSION_PATCH)"."QUOTE(EXPL_VERSION_TWEAK);

    static const char comp_name[] = EXPL_COMPILER_NAME;
    static const char comp_ver_str[] = QUOTE(EXPL_COMPILER_VERSION_MAJOR)"."QUOTE(EXPL_COMPILER_VERSION_MINOR)"."QUOTE(EXPL_COMPILER_VERSION_PATCH)"."QUOTE(EXPL_COMPILER_VERSION_TWEAK);

    printf("Compiler      : %s (%s)\n", comp_name, comp_ver_str);

    printf("Build Version : %s\n", ver_str);

    char buff[20];

    strftime(buff, 20, "%d-%m-%Y %H:%M:%S", localtime(&config_tmstmp));
    printf("Config Time   : %s\n", buff);

    strftime(buff, 20, "%d-%m-%Y %H:%M:%S", localtime(&build_tmstmp));
    printf("Build Time    : %s\n", buff);

    return 0;
}