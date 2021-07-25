#include "gtest/gtest.h"	// googletest header file

#include <string>
using
  std::string;

TEST (StrCompare, CStrEqual)
{
  // Arrange
  // Act
  // Assert
  EXPECT_STREQ ("test", "test");
}

TEST (ValueCompare, CValueEqual)
{
  // Arrange
  int
    foo = 5;
  int
    bar = 6;
  int
    sum = 0;
  // Act
  sum = foo + bar;
  // Assert
  EXPECT_EQ (sum, 11);
}
