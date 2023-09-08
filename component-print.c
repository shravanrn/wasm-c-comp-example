#include "combinedworld.h"

bool exports_wasi_cli_run_run() {

    wasi_cli_stdout_output_stream_t stdout_stream = wasi_cli_stdout_get_stdout();

    combinedworld_string_t to_print;
    wasmcon2023_greet_interface_greet(&to_print);


    combinedworld_list_u8_t str_p;
    str_p.ptr = to_print.ptr;
    str_p.len = to_print.len;

    combinedworld_tuple2_u64_wasi_io_streams_stream_status_t ret;

    // Doing some extra outputs to force a flush as blocking doesn't worj properly
    wasi_io_streams_blocking_write(stdout_stream, &str_p, &ret);
    wasi_io_streams_blocking_write(stdout_stream, &str_p, &ret);

    return true;
}
