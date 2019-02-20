
cpdef resolve(str path)
cpdef bytes pack(dict msg)
cpdef dict unpack(bytes incoming)
cpdef bytes pack_task(str task_id, str function, tuple args, dict kwargs)
cpdef tuple unpack_task(bytes incoming)

cpdef tuple parse_dsn(
        str dsn,
        default_port=*,
        default_db=*)
