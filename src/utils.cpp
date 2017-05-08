#include "pch.h"
#include "utils.h"

void warning_once(const std::string& msg) {
  static Function warning_once = Function("warning_once", Environment::namespace_env("RSQLite"));
  warning_once(msg);
}
