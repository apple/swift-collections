use std::alloc::{alloc, dealloc, Layout};
use std::collections::VecDeque;
use std::hint::black_box;

#[no_mangle]
unsafe extern "C" fn rust_vecdeque_create(
  mut start: *const isize,
  count: isize
) -> *mut VecDeque<isize> {
  let layout = Layout::new::<VecDeque<isize>>();
  let allocated = alloc(layout) as *mut VecDeque<isize>;

  let mut vec_deque = VecDeque::with_capacity(count as usize);

  for _ in 0..count {
    vec_deque.push_back(start.read());
    start = start.add(1);
  }

  allocated.write(vec_deque);

  allocated
}

#[no_mangle]
unsafe extern "C" fn rust_vecdeque_destroy(ptr: *mut VecDeque<isize>) {
  ptr.drop_in_place();
  dealloc(ptr as *mut u8, Layout::new::<VecDeque<isize>>());
}

#[no_mangle]
extern "C" fn rust_vecdeque_from_int_range(count: isize) {
  let mut vd = VecDeque::default();

  for i in 0..count {
    vd.push_back(black_box(i));
  }

  black_box(&vd);
}

#[no_mangle]
unsafe extern "C" fn rust_vecdeque_from_int_buffer(
  mut start: *const isize,
  count: isize
) {
  let mut vd = VecDeque::with_capacity(count as usize);

  for _ in 0..count {
    vd.push_back(start.read());
    start = start.add(1);
  }

  black_box(&vd);
}

#[no_mangle]
unsafe extern "C" fn rust_vecdeque_append_integers(
  mut start: *const isize,
  count: isize
) {
  let mut vd = VecDeque::default();

  for _ in 0..count {
    vd.push_back(start.read());
    start = start.add(1);
  }

  black_box(&vd);
}

#[no_mangle]
unsafe extern "C" fn rust_vecdeque_append_integers_with_capacity(
  mut start: *const isize,
  count: isize
) {
  let mut vd = VecDeque::with_capacity(count as usize);

  for _ in 0..count {
    vd.push_back(start.read());
    start = start.add(1);
  }

  black_box(&vd);
}

#[no_mangle]
unsafe extern "C" fn rust_vecdeque_prepend_integers(
  mut start: *const isize,
  count: isize
) {
  let mut vd = VecDeque::default();

  for _ in 0..count {
    vd.push_front(start.read());
    start = start.add(1);
  }

  black_box(&vd);
}

#[no_mangle]
unsafe extern "C" fn rust_vecdeque_prepend_integers_with_capacity(
  mut start: *const isize,
  count: isize
) {
  let mut vd = VecDeque::with_capacity(count as usize);

  for _ in 0..count {
    vd.push_front(start.read());
    start = start.add(1);
  }

  black_box(&vd);
}

#[no_mangle]
unsafe extern "C" fn rust_vecdeque_random_insertions(
  start: *const isize,
  count: isize
) {
  let mut deque = VecDeque::new();

  for i in 0..count {
    deque.insert(i as usize, start.wrapping_add(i as usize).read());
  }

  black_box(&deque);
}

#[no_mangle]
unsafe extern "C" fn rust_vecdeque_iterate(ptr: *mut u8) {
  let deque_ptr = ptr as *mut VecDeque<isize>;

  for e in &*deque_ptr {
    black_box(e);
  }
}
