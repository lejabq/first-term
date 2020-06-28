#ifndef VECTOR_H
#define VECTOR_H

#include <algorithm>
#include <cassert>
#include <cstdio>
#include <cstring>

template<typename T>
class vector {
 public:
  using iterator = T*;
  using const_iterator = T const*;

  // O(1) nothrow
  vector() noexcept = default;

  // O(N) strong
  vector(vector const& other)
      : vector() {
    if (other.size_ != 0) {
      data_ = allocate_data(other.size_);
      copy_elements(other.data_, data_, other.size_);
      size_ = other.size_;
      capacity_ = size_;
    }
  }

  // O(N) strong
  vector& operator=(vector const& other) {
    if (this != &other) {
      vector(other).swap(*this);
    }
    return *this;
  }

  // O(N) nothrow
  ~vector() {
    clear();
    operator delete(data_);
  }

  // O(1) nothrow
  T& operator[](size_t i) noexcept {
    return data_[i];
  }

  // O(1) nothrow
  T const& operator[](size_t i) const noexcept {
    return data_[i];
  }

  // O(1) nothrow
  T* data() noexcept {
    return data_;
  }

  // O(1) nothrow
  T const* data() const noexcept {
    return data_;
  }

  // O(1) nothrow
  size_t size() const noexcept {
    return size_;
  }

  // O(1) nothrow
  T& front() noexcept {
    return data_[0];
  }

  // O(1) nothrow
  T const& front() const noexcept {
    return data_[0];
  }

  // O(1) nothrow
  T& back() noexcept {
    return data_[size_ - 1];
  }

  // O(1) nothrow
  T const& back() const noexcept {
    return data_[size_ - 1];
  }

  // O(1)* strong
  void push_back(T const& element) {
    if (size_ == capacity_) {
      T tmp = element;
      new_buffer(calc_new_capacity());
      new(data_ + size_) T(tmp);
    } else {
      new(data_ + size_) T(element);
    }
    ++size_;
  }

  // O(1) nothrow
  void pop_back() noexcept {
    data_[--size_].~T();
  }

  // O(1) nothrow
  bool empty() const noexcept {
    return (size_ == 0);
  }

  // O(1) nothrow
  size_t capacity() const noexcept {
    return capacity_;
  }

  // O(N) strong
  void reserve(size_t new_capacity) {
    if (new_capacity > capacity_) {
      new_buffer(new_capacity);
    }
  }

  // O(N) strong
  void shrink_to_fit() {
    if (size_ < capacity_) {
      new_buffer(size_);
    }
  }

  // O(N) nothrow
  void clear() noexcept {
    destroy_elements(data_, size_);
    size_ = 0;
  }

  // O(1) nothrow
  void swap(vector& other) noexcept {
    std::swap(data_, other.data_);
    std::swap(size_, other.size_);
    std::swap(capacity_, other.capacity_);
  }

  // O(1) nothrow
  iterator begin() noexcept {
    return data_;
  }

  // O(1) nothrow
  iterator end() noexcept {
    return data_ + size_;
  }

  // O(1) nothrow
  const_iterator begin() const noexcept {
    return data_;
  }

  // O(1) nothrow
  const_iterator end() const noexcept {
    return data_ + size_;
  }

  // O(N) weak
  iterator insert(const_iterator pos, T const& element) {
    ptrdiff_t ind = pos - begin();
    push_back(element);
    iterator cur = begin() + ind;
    for (iterator i = end() - 1; i != cur; --i) {
      std::swap(*i, *(i - 1));
    }
    return cur;
  }

  // O(N) weak
  iterator erase(const_iterator pos) {
    return erase(pos, pos + 1);
  }

  // O(N) weak
  iterator erase(const_iterator first, const_iterator last) {
    ptrdiff_t f_shift = first - begin();
    ptrdiff_t l_shift = last - begin();
    ptrdiff_t cnt = l_shift - f_shift;
    if (cnt <= 0) {
      return begin() + l_shift;
    }
    for (iterator i = begin() + f_shift; i != end() - cnt; ++i) {
      std::iter_swap(i, i + cnt);
    }
    for (size_t i = 0; i != cnt; ++i) {
      pop_back();
    }
    return begin() + f_shift;
  }

 private:
  size_t calc_new_capacity() const noexcept {
    return (capacity_ == 0 ? 1 : capacity_ * 2);
  }

  void new_buffer(size_t new_capacity) {
    T* new_data = nullptr;
    if (new_capacity != 0) {
      new_data = allocate_data(new_capacity);
    }
    if (size_ != 0) {
      try {
        copy_elements(data_, new_data, size_);
      } catch (...) {
        operator delete(new_data);
        throw;
      }
      destroy_elements(data_, size_);
    }
    operator delete(data_);
    data_ = new_data;
    capacity_ = new_capacity;
  }

  static void copy_elements(T* src, T* dst, size_t size) {
    if (std::is_trivially_copy_constructible<T>::value) {
      std::memcpy(dst, src, size * sizeof(T));
    } else {
      size_t i = 0;
      try {
        for (; i != size; ++i) {
          new(dst + i) T(src[i]);
        }
      } catch (...) {
        destroy_elements(dst, i);
        throw;
      }
    }
  }

  static void destroy_elements(T* data, size_t size) noexcept {
    while (size > 0) {
      data[--size].~T();
    }
  }

  static T* allocate_data(size_t n) {
    return static_cast<T*>(operator new(n * sizeof(T)));
  }

  T* data_ = nullptr;
  size_t size_ = 0;
  size_t capacity_ = 0;
};

#endif // VECTOR_H
