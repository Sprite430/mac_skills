---
name: partial-javac-compile
description: 在 Maven 项目因与目标类无关的 Java 源码冲突而无法整体编译时，使用 javac 只编译用户明确指定的一个或少量互相依赖的主源码或测试源码，复用已有 target/classes 和 Maven 依赖 classpath，生成局部 .class。适用于局部语法和类型验证、临时 class 产物；不适用于目标源码依赖冲突代码、需要完整 Maven 构建、JPMS、自定义编译器或特殊注解处理器的场景。
---

# Maven 局部 javac 编译

只向 `javac` 传入用户明确指定的源码，绕过项目中与目标类无关的冲突源码。把结果写入独立临时目录，不覆盖模块现有构建产物。

## 执行原则

- 先确认目标源码不依赖发生冲突的源码。
- 复用已有 `target/classes`，不要默认执行 `mvn clean`。
- 使用空 `-sourcepath`，禁止 `javac` 隐式查找其他项目源码。
- 把互相依赖的少量目标源码一次传给同一个 `javac` 命令。
- 任一命令失败时立即停止，不要吞掉编译错误。
- 以下 classpath 使用 `:` 分隔，只适用于 macOS/Linux。

## 编译前检查

先确认 Maven 与 `javac` 使用的 JDK：

```bash
mvn -version
javac -version
```

再确认以下条件：

1. 目标模块存在 `pom.xml`。
2. 目标 Java 文件路径正确。
3. 目标类引用的同模块类型已经存在于 `target/classes`，或者也会在本次一起编译。
4. 目标类引用的其他模块类型已经存在于对应模块的 `target/classes` 或本地 Maven 仓库。

如果目标类依赖的类型只存在于尚未编译的冲突源码中，停止局部编译。不要为了绕过错误而使用旧版或无关 `.class` 冒充依赖。

## 编译主源码

先替换模块目录和目标源码路径，再执行：

```bash
set -euo pipefail

MODULE_DIR="path/to/module"
SOURCE_FILE="$MODULE_DIR/src/main/java/com/example/YourClass.java"
WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/partial-javac.XXXXXX")"
OUT_DIR="$WORK_DIR/out"
EMPTY_SOURCE_PATH="$WORK_DIR/empty-source-path"
CP_FILE="$WORK_DIR/compile-classpath.txt"

test -f "$MODULE_DIR/pom.xml"
test -f "$SOURCE_FILE"
mkdir -p "$OUT_DIR" "$EMPTY_SOURCE_PATH"

mvn -f "$MODULE_DIR/pom.xml" dependency:build-classpath \
  -DincludeScope=compile \
  -Dmdep.outputFile="$CP_FILE"

MAVEN_CP="$(tr -d '\r\n' < "$CP_FILE")"
COMPILE_CP="$MODULE_DIR/target/classes"
if [[ -n "$MAVEN_CP" ]]; then
  COMPILE_CP="$COMPILE_CP:$MAVEN_CP"
fi

javac -encoding UTF-8 \
  -sourcepath "$EMPTY_SOURCE_PATH" \
  -cp "$COMPILE_CP" \
  -d "$OUT_DIR" \
  "$SOURCE_FILE"

printf '输出目录: %s\n' "$OUT_DIR"
find "$OUT_DIR" -type f -name '*.class' -print | sort
```

`includeScope=compile` 包含 Maven 的 compile、provided、system scope，不包含 test 和 runtime-only 依赖。

空 `-sourcepath` 是绕过无关源码冲突的关键：`javac` 只编译命令行中明确传入的源码，并从 classpath 查找其余类型。

## 加入其他模块的已编译类

如果目标类依赖同一仓库中其他模块的现有 `.class`，把对应 `target/classes` 加入 `COMPILE_CP`：

```bash
COMPILE_CP="$COMPILE_CP:/absolute/path/to/dependency-module/target/classes"
```

只加入已确认与当前源码匹配的构建产物，不要把其他模块的 `src/main/java` 加入 sourcepath。

## 编译测试源码

测试源码使用 test scope。`includeScope=test` 已包含所有依赖 scope，不需要再生成并拼接一份 compile classpath。

```bash
set -euo pipefail

MODULE_DIR="path/to/module"
SOURCE_FILE="$MODULE_DIR/src/test/java/com/example/RunYourTest.java"
TEST_CLASS="com.example.RunYourTest"
WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/partial-javac-test.XXXXXX")"
OUT_DIR="$WORK_DIR/out"
EMPTY_SOURCE_PATH="$WORK_DIR/empty-source-path"
CP_FILE="$WORK_DIR/test-classpath.txt"

test -f "$MODULE_DIR/pom.xml"
test -f "$SOURCE_FILE"
mkdir -p "$OUT_DIR" "$EMPTY_SOURCE_PATH"

mvn -f "$MODULE_DIR/pom.xml" dependency:build-classpath \
  -DincludeScope=test \
  -Dmdep.outputFile="$CP_FILE"

MAVEN_CP="$(tr -d '\r\n' < "$CP_FILE")"
TEST_CP="$MODULE_DIR/target/test-classes:$MODULE_DIR/target/classes:$MODULE_DIR/src/test/resources:$MODULE_DIR/src/main/resources"
if [[ -n "$MAVEN_CP" ]]; then
  TEST_CP="$TEST_CP:$MAVEN_CP"
fi

javac -encoding UTF-8 \
  -sourcepath "$EMPTY_SOURCE_PATH" \
  -cp "$TEST_CP" \
  -d "$OUT_DIR" \
  "$SOURCE_FILE"

find "$OUT_DIR" -type f -name '*.class' -print | sort

# 只对包含 main 方法的 standalone 测试类执行此命令。
java -cp "$OUT_DIR:$TEST_CP" "$TEST_CLASS"
```

JUnit 测试只做局部编译时，到 `javac` 成功即可。需要执行 JUnit 时，使用项目已有测试运行器或完整 Maven 测试流程。

## 一次编译少量相关源码

如果两个目标源码互相依赖，使用数组一次传给 `javac`。不要逐个编译，也不要使用覆盖整个包目录的通配符。

```bash
SOURCE_FILES=(
  "$MODULE_DIR/src/main/java/com/example/First.java"
  "$MODULE_DIR/src/main/java/com/example/Second.java"
)

javac -encoding UTF-8 \
  -sourcepath "$EMPTY_SOURCE_PATH" \
  -cp "$COMPILE_CP" \
  -d "$OUT_DIR" \
  "${SOURCE_FILES[@]}"

find "$OUT_DIR" -type f -name '*.class' -print | sort
```

## 停止条件

遇到以下情况时停止并说明局部编译不适用：

- 目标类直接依赖发生冲突或尚未编译的项目源码。
- 目标类依赖 Maven 构建阶段生成的源码，但对应 `.class` 尚不存在。
- 项目依赖特殊 annotation processor、Maven Toolchain、自定义编译器参数或 JPMS module-path。
- `target/classes` 明显陈旧，无法确认是否与当前源码和依赖版本一致。
- 目标是验证 Spring 注入、AOP、事务、资源装配等运行时行为。

## 结果与交付

- 局部编译成功表示目标源码能在当前 classpath 下完成语法和类型检查。
- 局部编译不能代替完整的 `mvn compile`、`mvn test` 或集成验证。
- 如果 `.class` 用于临时交付，使用与目标环境一致的 JDK。
- 交付输出目录中与目标类相关的全部文件，包括内部类、匿名类产生的 `YourClass$*.class`，不要只复制主类文件。
- 保留命令输出和临时目录路径，便于核对本次实际生成的产物。
