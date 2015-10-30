context("clusterFunctions")

test_that("clusterFunctions constructor", {
  reg = makeTempRegistry(FALSE)
  cf = reg$cluster.functions
  expect_is(cf, "ClusterFunctions")
  expect_set_equal(names(cf), c("name", "submitJob", "killJob", "listJobs", "array.envir.var", "store.job"))
  expect_output(cf, "ClusterFunctions for mode")
})


test_that("submitJobResult", {
  x = makeSubmitJobResult(0, 99)
  expect_is(x, "SubmitJobResult")
  expect_identical(x$status, 0L)
  expect_identical(x$batch.id, 99)
  expect_identical(x$msg, "OK")

  x = makeSubmitJobResult(1, 99)
  expect_is(x, "SubmitJobResult")
  expect_identical(x$msg, "TEMPERROR")

  x = makeSubmitJobResult(101, 99)
  expect_is(x, "SubmitJobResult")
  expect_identical(x$msg, "ERROR")

  expect_output(x, "submission result")

  x = cfHandleUnknownSubmitError(cmd = "ls", exit.code = 42L, output = "answer to life")
  expect_is(x, "SubmitJobResult")
  expect_true(all(stri_detect_fixed(x$msg, c("ls", "42", "answer to life"))))
})

test_that("brew", {
  fn = tempfile()
  lines = c("####", " ", "!!!", "foo=<%= job.hash %>")
  writeLines(lines, fn)

  res = stri_split_fixed(cfReadBrewTemplate(fn), "\n")[[1]]
  assertCharacter(res, len = 3)
  expect_equal(sum(stri_detect_fixed(res, "job.hash")), 1)

  res = stri_split_fixed(cfReadBrewTemplate(fn, comment.string = "###"), "\n")[[1]]
  assertCharacter(res, len = 2)
  expect_equal(sum(stri_detect_fixed(res, "job.hash")), 1)

  reg = makeTempRegistry(FALSE)
  ids = batchMap(identity, 1:2, reg = reg)
  jc = makeJobCollection(1, reg = reg)
  template = cfReadBrewTemplate(fn, comment.string = "###")

  fn = cfBrewTemplate(template = template, jc = jc, reg = reg)
  brewed = readLines(fn)
  expect_equal(brewed[1], "!!!")
  expect_equal(brewed[2], sprintf("foo=%s", jc$job.hash))
})

test_that("brew", {
  skip_on_os("windows")
  x = runOSCommand("ls", find.package("batchtools"))
  expect_list(x, names = "named", len = 2)
  expect_identical(x$exit.code, 0L)
  expect_true(all(c("DESCRIPTION", "NAMESPACE", "NEWS.md") %in% x$output))
})
