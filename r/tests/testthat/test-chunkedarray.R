# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

context("arrow::ChunkedArray")

test_that("ChunkedArray", {
  x <- chunked_array(1:10, 1:10, 1:5)
  expect_equal(x$type(), int32())
  expect_equal(x$num_chunks(), 3L)
  expect_equal(x$length(), 25L)
  expect_equal(x$as_vector(), c(1:10, 1:10, 1:5))

  y <- x$Slice(8)
  expect_equal(y$type(), int32())
  expect_equal(y$num_chunks(), 3L)
  expect_equal(y$length(), 17L)
  expect_equal(y$as_vector(), c(9:10, 1:10, 1:5))

  z <- x$Slice(8, 5)
  expect_equal(z$type(), int32())
  expect_equal(z$num_chunks(), 2L)
  expect_equal(z$length(), 5L)
  expect_equal(z$as_vector(), c(9:10, 1:3))

  x_dbl <- chunked_array(c(1,2,3), c(4,5,6))
  expect_equal(x_dbl$type(), float64())
  expect_equal(x_dbl$num_chunks(), 2L)
  expect_equal(x_dbl$length(), 6L)
  expect_equal(x_dbl$as_vector(), as.numeric(1:6))

  y_dbl <- x_dbl$Slice(2)
  expect_equal(y_dbl$type(), float64())
  expect_equal(y_dbl$num_chunks(), 2L)
  expect_equal(y_dbl$length(), 4L)
  expect_equal(y_dbl$as_vector(), as.numeric(3:6))

  z_dbl <- x_dbl$Slice(2, 2)
  expect_equal(z_dbl$type(), float64())
  expect_equal(z_dbl$num_chunks(), 2L)
  expect_equal(z_dbl$length(), 2L)
  expect_equal(z_dbl$as_vector(), as.numeric(3:4))
})

test_that("ChunkedArray handles !!! splicing", {
  data <- list(1, 2, 3)
  x <- chunked_array(!!!data)
  expect_equal(x$type(), float64())
  expect_equal(x$num_chunks(), 3L)
})

test_that("ChunkedArray handles NA", {
  data <- list(1:10, c(NA, 2:10), c(1:3, NA, 5L))
  x <- chunked_array(!!!data)
  expect_equal(x$type(), int32())
  expect_equal(x$num_chunks(), 3L)
  expect_equal(x$length(), 25L)
  expect_equal(x$as_vector(), c(1:10, c(NA, 2:10), c(1:3, NA, 5)))

  chunks <- x$chunks()
  expect_equal(Array__Mask(chunks[[1]]), !is.na(data[[1]]))
  expect_equal(Array__Mask(chunks[[2]]), !is.na(data[[2]]))
  expect_equal(Array__Mask(chunks[[3]]), !is.na(data[[3]]))
})

test_that("ChunkedArray supports logical vectors (ARROW-3341)", {
  # with NA
  data <- purrr::rerun(3, sample(c(TRUE, FALSE, NA), 100, replace = TRUE))
  arr_lgl <- chunked_array(!!!data)
  expect_equal(arr_lgl$length(), 300L)
  expect_equal(arr_lgl$null_count(), sum(unlist(map(data, is.na))))

  chunks <- arr_lgl$chunks()
  expect_identical(data[[1]], chunks[[1]]$as_vector())
  expect_identical(data[[2]], chunks[[2]]$as_vector())
  expect_identical(data[[3]], chunks[[3]]$as_vector())

  # without NA
  data <- purrr::rerun(3, sample(c(TRUE, FALSE), 100, replace = TRUE))
  arr_lgl <- chunked_array(!!!data)
  expect_equal(arr_lgl$length(), 300L)
  expect_equal(arr_lgl$null_count(), sum(unlist(map(data, is.na))))

  chunks <- arr_lgl$chunks()
  expect_identical(data[[1]], chunks[[1]]$as_vector())
  expect_identical(data[[2]], chunks[[2]]$as_vector())
  expect_identical(data[[3]], chunks[[3]]$as_vector())
})

test_that("ChunkedArray supports character vectors (ARROW-3339)", {
  data <- list(
    c("itsy", NA, "spider"),
    c("Climbed", "up", "the", "water", "spout"),
    c("Down", "came", "the", "rain"),
    "And washed the spider out. "
  )
  arr_chr <- chunked_array(!!!data)
  expect_equal(arr_chr$length(), length(unlist(data)))
  expect_equal(arr_chr$null_count(), 1L)

  chunks <- arr_chr$chunks()
  expect_equal(data, purrr::map(chunks, ~.$as_vector()))
})

