#include <stdio.h>
#include <string.h>

#include "zip.h"

// callback function
int on_extract_entry(const char *filename, void *arg) {
    static int i = 0;
    int n = *(int *)arg;
    printf("Extracted: %s (%d of %d)\n", filename, ++i, n); 

    return 0;
}

int main(int argc, const char** argv) {
    /* 
       Create a new zip archive with default compression level (6)     
    */
	/*
    struct zip_t *zip = zip_open("foo.zip", ZIP_DEFAULT_COMPRESSION_LEVEL, 0);
    // we should check if zip is NULL
    {
        zip_entry_open(zip, "foo-1.txt");
        {
            char *buf = "Some data here...";
            zip_entry_write(zip, buf, strlen(buf));
        }
        zip_entry_close(zip);

        zip_entry_open(zip, "foo-2.txt");
        {
            // merge 3 files into one entry and compress them on-the-fly.
            zip_entry_fwrite(zip, "foo-2.1.txt");
            zip_entry_fwrite(zip, "foo-2.2.txt");
            zip_entry_fwrite(zip, "foo-2.3.txt");
        }
        zip_entry_close(zip);       
    }
    // always remember to close and release resources
    zip_close(zip);
	*/

    /*
        Extract a zip archive into /tmp folder
    */
    int arg = 5;
    zip_extract(argv[1], "/Users/mrsang/Downloads/zip-master/src/tmp", on_extract_entry, &arg);

    return 0;
}