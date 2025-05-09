library(dplyr)

# check the default call -----------------
rdf_file <- system.file(
  "extdata/Scenario/ISM1988_2014,2007Dems,IG,Most/KeySlots.rdf", 
  package = "RWDataPlyr"
)
rdftbl <- expect_warning(
  read_rdf(rdf_file) %>%
    rdf_to_rwtbl()
)
rdftbl2 <- rdf_to_rwtbl2(rdf_file)
# need to make sure columns are both in the same order
rdftbl2 <- select_at(rdftbl2, colnames(rdftbl))

reqCols <- RWDataPlyr:::req_rwtbl_cols()
exp_atts <- c("mrm_config_name", "owner", "description", "create_date", 
              "n_traces")

test_that("dimensions are as expected", {
  expect_equal(dim(rdftbl), dim(rdftbl2))
  expect_true(all(colnames(rdftbl2) %in% c(reqCols, "Year", "Month")))
})

test_that("attributes are as expected and match the rdf", {
  expect_true(all(exp_atts %in% names(attributes(rdftbl2))))
})

test_that("function results match", {
  expect_equal(rdftbl, rdftbl2)
})

test_that("trace number starts at correct value", {
  expect_equal(min(rdftbl$TraceNumber), 1)
  # this rdf starts with trace 2 instead of 1
  tmp <- rdf_to_rwtbl2("../rdfs/starts_trace_2.rdf")
  tmp2 <- expect_warning(rdf_to_rwtbl(read_rdf("../rdfs/starts_trace_2.rdf")))
  expect_equal(min(tmp$TraceNumber), 2)
  expect_equal(range(tmp2$TraceNumber), range(tmp$TraceNumber))
})

# check the add_ym options ---------------
rdftbl3 <- expect_warning(read_rdf(rdf_file) %>% rdf_to_rwtbl(add_ym = FALSE))
rdftbl4 <- rdf_to_rwtbl2(rdf_file, add_ym = FALSE) %>% 
  select_at(colnames(rdftbl3))
test_that("different versions match", {
  expect_equal(rdftbl3, rdftbl4)
})

test_that("no ym tbl matches orig tbl", {
  expect_identical(rdftbl4, rdftbl2 %>% select(-Year, -Month))
})

test_that("invalid add_ym values cause errors", {
  expect_error(rdf_to_rwtbl2(rdf_file, add_ym = NA))
  expect_error(rdf_to_rwtbl2(rdf_file, add_ym = "true"))
  expect_error(rdf_to_rwtbl2(rdf_file, add_ym = 7))
  expect_error(rdf_to_rwtbl2(rdf_file, add_ym = c(FALSE, TRUE, NA)))
})

# check the scenario option -------------
rdftbl5 <- expect_warning(
  read_rdf(rdf_file) %>% 
    rdf_to_rwtbl(scenario = "DNF,CT")
)
rdftbl6 <- rdf_to_rwtbl2(rdf_file, scenario = "DNF,CT") %>%
  select_at(colnames(rdftbl5))

rdftbl7 <- expect_warning(
  read_rdf(rdf_file) %>% 
    rdf_to_rwtbl(scenario = 1, add_ym = FALSE)
)
rdftbl8 <- rdf_to_rwtbl2(rdf_file, scenario = 1, add_ym = FALSE) %>%
  select_at(colnames(rdftbl7))
test_that("methods match", {
  expect_equal(rdftbl5, rdftbl6)
  expect_equal(rdftbl7, rdftbl8)
})

test_that("no add scenario tbl matches orig tbl", {
  expect_identical(rdftbl6 %>% select(-Scenario), rdftbl2)
  expect_identical(
    rdftbl8 %>% select(-Scenario), 
    rdftbl2 %>% select(-Year, -Month)
  )
})

test_that("scenario options error properly", {
  expect_error(rdf_to_rwtbl2(rdf_file, scenario = c("DNF,CT", "DNF,C1")))
  expect_error(rdf_to_rwtbl2(rdf_file, scenario = 1:6, add_ym = FALSE))
  expect_error(rdf_to_rwtbl2(rdf_file, scenario = character(0), add_ym = FALSE))
})

# check the keep_cols option ------------
rdftbl3 <- expect_warning(read_rdf(rdf_file) %>% rdf_to_rwtbl(keep_cols = TRUE))
rdftbl4 <- rdf_to_rwtbl2(rdf_file, keep_cols = TRUE) %>%
  select_at(colnames(rdftbl3))

rdftbl5 <- expect_warning(
  read_rdf(rdf_file) %>%
    rdf_to_rwtbl(keep_cols = c("ObjectName", "Unit"), scenario = 1)
)
rdftbl6 <- rdf_to_rwtbl2(
  rdf_file, 
  keep_cols = c("ObjectName", "Unit"), 
  scenario = 1
) %>% 
  select_at(colnames(rdftbl5))

test_that("methods match", {
  expect_equal(rdftbl3, rdftbl4)
  expect_equal(rdftbl5, rdftbl6)
})

test_that("keep_cols warnings post correctly", {
  expect_warning(
    tmp <- rdf_to_rwtbl2(rdf_file, keep_cols = c("ObjectName", "missing")),
    paste0(
      "The following columns specified by 'keep_cols' were not found in the rwtbl:\n",
      "    missing"
    )
  )
  
  expect_true(all(colnames(tmp) %in% c(reqCols, "Year", "Month", "ObjectName")))
  
  expect_warning(
    tmp <- rdf_to_rwtbl2(rdf_file, keep_cols = c("ObjectName", "missing", "a")),
    paste0(
      "The following columns specified by 'keep_cols' were not found in the rwtbl:\n",
      "    missing, a"
    )
  ) 
  expect_true(all(colnames(tmp) %in% c(reqCols, "Year", "Month", "ObjectName")))
  
  expect_error(rdf_to_rwtbl2(rdf_file, keep_cols = c(FALSE, TRUE)))
  expect_error(rdf_to_rwtbl2(rdf_file, keep_cols = NULL))
})


# check the default call annual values-----------------
context("check rdf_to_rwtbl with annual rdf file")

rdf_file <- system.file(
  "extdata/Scenario/ISM1988_2014,2007Dems,IG,Most/SystemConditions.rdf", 
  package = "RWDataPlyr"
)

rdftbl <- expect_warning(read_rdf(rdf_file) %>% rdf_to_rwtbl())
rdftbl2 <- rdf_to_rwtbl2(rdf_file) %>% select_at(colnames(rdftbl))

test_that("methods match for annual rdf", {
  expect_equal(rdftbl, rdftbl2)
})

# check rwtbl for scalar slots ----------------
context("check rdf_to_rwtbl with scalar rdf files")
test_that("methods match for scalar slots", {
  xx <- expect_warning(read_rdf("../rdfs/scalar.rdf") %>% rdf_to_rwtbl())
  xx2 <- rdf_to_rwtbl2("../rdfs/scalar.rdf") %>% select_at(colnames(xx))
  expect_equal(xx, xx2)
  xx <- expect_warning(read_rdf("../rdfs/scalar_series.rdf") %>% rdf_to_rwtbl())
  xx2 <- rdf_to_rwtbl2("../rdfs/scalar_series.rdf") %>% select_at(colnames(xx))
  expect_equal(xx, xx2)
  xx <- expect_warning(read_rdf("../rdfs/series.rdf") %>% rdf_to_rwtbl())
  xx2 <- rdf_to_rwtbl2("../rdfs/series.rdf") %>% select_at(colnames(xx))
  expect_equal(xx, xx2)
})

