#include <sys/types.h>
#include <libgen.h>
#include <assert.h>
#include <limits.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#ifdef __linux__
static const char* const self_exe = "/proc/self/exe";
size_t filename_buffer_size()
{
	size_t result;
#ifdef PATH_MAX
	result = PATH_MAX;
#else
	ssize_t default_size = 1024; /* Random fallback */
	result = pathconf(self_exe, _PC_PATH_MAX);
	if (result <= 0)
		result = default_size;
#endif

	return result;
}
#endif

int main(int argc, char **argv)
{
	if (argc > 0)
		printf("argv[0] \t\"\%s\"\n", argv[0]);

#ifdef __linux__
	size_t bsize = filename_buffer_size();
	char *buffer = malloc(bsize);
	if (!buffer) {
		perror("malloc");
		abort();
	}

	ssize_t allocated = readlink(self_exe, buffer, bsize);
	if ( allocated < 0) {
		perror("readlink");
		abort();
	}
	buffer[allocated] = '\0';

	char *canonical = realpath(buffer, 0);
	if (!canonical) {
		perror("realpath");
		abort();
	}

	printf("realpath\t\"%s\"\n", canonical);

	char *dirname_input = strdup(canonical);
	if (!dirname_input) {
		perror("strdup(dirname_input)");
		abort();
	}
	char *dir = dirname(dirname_input);
	assert(dir);
	printf("dirname \t\"%s\"\n", dir);
	free(dirname_input);

	char *basename_input = strdup(canonical);
	if (!basename_input) {
		perror("strdup(basename_input)");
		abort();
	}
	char *base = basename(basename_input);
	assert(base);
	printf("basename\t\"%s\"\n", base);
	free(basename_input);


	free(canonical);
	free(buffer);
#endif
	return 0;
}


/* Emacs
 * Local Variables:
 * compile-command: "cc -o argv0 -g -O0 -Wall -Wextra -Werror argv0.c"
 * End:
 */ 
