* Run `sudo apt-get install libgtest-dev`
* Link the libraries `gtest` and `pthread`
* Clone the gtest repo and include it in the compiler paths
* Check for memory leaks by adding the compiler flag `-fsanitize=leak`
* Use the `TEST()` macro to define and name a test function
* Invoke `RUN_ALL_TESTS()` to run all tests , it returns 0 if all the tests are successful, otherwise 1
* Test_F (test fixtures) are used to configure several test cases with same steps
* Mocks are used to stub interfaces for the unit test

* Tests are constructed as
** Arrange: to declare variables
** Act:     to do operations
** Assert   to check expected against actual (use that order in test functions)

---
###Basic Assertions###

These assertions do basic true/false condition testing.
| Fatal assertion          | Nonfatal assertion       | Verifies          |
|--------------------------|--------------------------|-------------------|
| ASSERT_TRUE(condition);  | EXPECT_TRUE(condition);  | condition is true |
| ASSERT_FALSE(condition); | EXPECT_FALSE(condition); | condition         |

###Binary Comparison###

This section describes assertions that compare two values.
| Fatal assertion       | Nonfatal assertion    | Verifies     |
|-----------------------|-----------------------|--------------|
| ASSERT_EQ(val1,val2); | EXPECT_EQ(val1,val2); | val1 == val2 |
| ASSERT_NE(val1,val2); | EXPECT_NE(val1,val2); | val1 != val2 |
| ASSERT_LT(val1,val2); | EXPECT_LT(val1,val2); | val1 < val2  |
| ASSERT_LE(val1,val2); | EXPECT_LE(val1,val2); | val1 <= val2 |
| ASSERT_GT(val1,val2); | EXPECT_GT(val1,val2); | val1 > val2  |
| ASSERT_GE(val1,val2); | EXPECT_GE(val1,val2); | val1 >= val2 |

###String Comparison###

The assertions in this group compare two C strings. If you want to compare two string objects, use EXPECT_EQ, EXPECT_NE, and etc instead.
| Fatal assertion              | Nonfatal assertion           | Verifies                                                |
|------------------------------|------------------------------|---------------------------------------------------------|
| ASSERT_STREQ(str1,str2);     | EXPECT_STREQ(str1,_str_2);   | the two C strings have the same content                 |
| ASSERT_STRNE(str1,str2);     | EXPECT_STRNE(str1,str2);     | the two C strings have different content                |
| ASSERT_STRCASEEQ(str1,str2); | EXPECT_STRCASEEQ(str1,str2); | the two C strings have the same content, ignoring case  |
| ASSERT_STRCASENE(str1,str2); | EXPECT_STRCASENE(str1,str2); | the two C strings have different content, ignoring case |
| ASSERT_GT(val1,val2);        | EXPECT_GT(val1,val2);        | val1 > val2                                             |
| ASSERT_GE(val1,val2);        | EXPECT_GE(val1,val2);        | val1 >= val2                                            |

