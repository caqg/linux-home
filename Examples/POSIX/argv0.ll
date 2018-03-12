; ModuleID = 'argv0.c'
target datalayout = "e-m:e-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

@.str = private unnamed_addr constant [15 x i8] c"argv[0] \09\22%s\22\0A\00", align 1
@.str1 = private unnamed_addr constant [7 x i8] c"malloc\00", align 1
@self_exe = internal constant i8* getelementptr inbounds ([15 x i8]* @.str12, i32 0, i32 0), align 8
@.str2 = private unnamed_addr constant [9 x i8] c"readlink\00", align 1
@.str3 = private unnamed_addr constant [9 x i8] c"realpath\00", align 1
@.str4 = private unnamed_addr constant [15 x i8] c"realpath\09\22%s\22\0A\00", align 1
@.str5 = private unnamed_addr constant [22 x i8] c"strdup(dirname_input)\00", align 1
@.str6 = private unnamed_addr constant [4 x i8] c"dir\00", align 1
@.str7 = private unnamed_addr constant [8 x i8] c"argv0.c\00", align 1
@__PRETTY_FUNCTION__.main = private unnamed_addr constant [23 x i8] c"int main(int, char **)\00", align 1
@.str8 = private unnamed_addr constant [15 x i8] c"dirname \09\22%s\22\0A\00", align 1
@.str9 = private unnamed_addr constant [23 x i8] c"strdup(basename_input)\00", align 1
@.str10 = private unnamed_addr constant [5 x i8] c"base\00", align 1
@.str11 = private unnamed_addr constant [15 x i8] c"basename\09\22%s\22\0A\00", align 1
@.str12 = private unnamed_addr constant [15 x i8] c"/proc/self/exe\00", align 1

; Function Attrs: nounwind uwtable
define i64 @filename_buffer_size() #0 {
  %result = alloca i64, align 8
  store i64 4096, i64* %result, align 8
  %1 = load i64* %result, align 8
  ret i64 %1
}

; Function Attrs: nounwind uwtable
define i32 @main(i32 %argc, i8** %argv) #0 {
  %1 = alloca i32, align 4
  %2 = alloca i32, align 4
  %3 = alloca i8**, align 8
  %bsize = alloca i64, align 8
  %buffer = alloca i8*, align 8
  %allocated = alloca i64, align 8
  %canonical = alloca i8*, align 8
  %dirname_input = alloca i8*, align 8
  %dir = alloca i8*, align 8
  %basename_input = alloca i8*, align 8
  %base = alloca i8*, align 8
  store i32 0, i32* %1
  store i32 %argc, i32* %2, align 4
  store i8** %argv, i8*** %3, align 8
  %4 = load i32* %2, align 4
  %5 = icmp sgt i32 %4, 0
  br i1 %5, label %6, label %11

; <label>:6                                       ; preds = %0
  %7 = load i8*** %3, align 8
  %8 = getelementptr inbounds i8** %7, i64 0
  %9 = load i8** %8, align 8
  %10 = call i32 (i8*, ...)* @printf(i8* getelementptr inbounds ([15 x i8]* @.str, i32 0, i32 0), i8* %9)
  br label %11

; <label>:11                                      ; preds = %6, %0
  %12 = call i64 @filename_buffer_size()
  store i64 %12, i64* %bsize, align 8
  %13 = load i64* %bsize, align 8
  %14 = call noalias i8* @malloc(i64 %13) #4
  store i8* %14, i8** %buffer, align 8
  %15 = load i8** %buffer, align 8
  %16 = icmp ne i8* %15, null
  br i1 %16, label %18, label %17

; <label>:17                                      ; preds = %11
  call void @perror(i8* getelementptr inbounds ([7 x i8]* @.str1, i32 0, i32 0))
  call void @abort() #5
  unreachable

; <label>:18                                      ; preds = %11
  %19 = load i8** @self_exe, align 8
  %20 = load i8** %buffer, align 8
  %21 = load i64* %bsize, align 8
  %22 = call i64 @readlink(i8* %19, i8* %20, i64 %21) #4
  store i64 %22, i64* %allocated, align 8
  %23 = load i64* %allocated, align 8
  %24 = icmp slt i64 %23, 0
  br i1 %24, label %25, label %26

; <label>:25                                      ; preds = %18
  call void @perror(i8* getelementptr inbounds ([9 x i8]* @.str2, i32 0, i32 0))
  call void @abort() #5
  unreachable

; <label>:26                                      ; preds = %18
  %27 = load i64* %allocated, align 8
  %28 = load i8** %buffer, align 8
  %29 = getelementptr inbounds i8* %28, i64 %27
  store i8 0, i8* %29, align 1
  %30 = load i8** %buffer, align 8
  %31 = call i8* @realpath(i8* %30, i8* null) #4
  store i8* %31, i8** %canonical, align 8
  %32 = load i8** %canonical, align 8
  %33 = icmp ne i8* %32, null
  br i1 %33, label %35, label %34

; <label>:34                                      ; preds = %26
  call void @perror(i8* getelementptr inbounds ([9 x i8]* @.str3, i32 0, i32 0))
  call void @abort() #5
  unreachable

; <label>:35                                      ; preds = %26
  %36 = load i8** %canonical, align 8
  %37 = call i32 (i8*, ...)* @printf(i8* getelementptr inbounds ([15 x i8]* @.str4, i32 0, i32 0), i8* %36)
  %38 = load i8** %canonical, align 8
  %39 = call noalias i8* @strdup(i8* %38) #4
  store i8* %39, i8** %dirname_input, align 8
  %40 = load i8** %dirname_input, align 8
  %41 = icmp ne i8* %40, null
  br i1 %41, label %43, label %42

; <label>:42                                      ; preds = %35
  call void @perror(i8* getelementptr inbounds ([22 x i8]* @.str5, i32 0, i32 0))
  call void @abort() #5
  unreachable

; <label>:43                                      ; preds = %35
  %44 = load i8** %dirname_input, align 8
  %45 = call i8* @dirname(i8* %44) #4
  store i8* %45, i8** %dir, align 8
  %46 = load i8** %dir, align 8
  %47 = icmp ne i8* %46, null
  br i1 %47, label %48, label %49

; <label>:48                                      ; preds = %43
  br label %51

; <label>:49                                      ; preds = %43
  call void @__assert_fail(i8* getelementptr inbounds ([4 x i8]* @.str6, i32 0, i32 0), i8* getelementptr inbounds ([8 x i8]* @.str7, i32 0, i32 0), i32 62, i8* getelementptr inbounds ([23 x i8]* @__PRETTY_FUNCTION__.main, i32 0, i32 0)) #5
  unreachable
                                                  ; No predecessors!
  br label %51

; <label>:51                                      ; preds = %50, %48
  %52 = load i8** %dir, align 8
  %53 = call i32 (i8*, ...)* @printf(i8* getelementptr inbounds ([15 x i8]* @.str8, i32 0, i32 0), i8* %52)
  %54 = load i8** %dirname_input, align 8
  call void @free(i8* %54) #4
  %55 = load i8** %canonical, align 8
  %56 = call noalias i8* @strdup(i8* %55) #4
  store i8* %56, i8** %basename_input, align 8
  %57 = load i8** %basename_input, align 8
  %58 = icmp ne i8* %57, null
  br i1 %58, label %60, label %59

; <label>:59                                      ; preds = %51
  call void @perror(i8* getelementptr inbounds ([23 x i8]* @.str9, i32 0, i32 0))
  call void @abort() #5
  unreachable

; <label>:60                                      ; preds = %51
  %61 = load i8** %basename_input, align 8
  %62 = call i8* @__xpg_basename(i8* %61) #4
  store i8* %62, i8** %base, align 8
  %63 = load i8** %base, align 8
  %64 = icmp ne i8* %63, null
  br i1 %64, label %65, label %66

; <label>:65                                      ; preds = %60
  br label %68

; <label>:66                                      ; preds = %60
  call void @__assert_fail(i8* getelementptr inbounds ([5 x i8]* @.str10, i32 0, i32 0), i8* getelementptr inbounds ([8 x i8]* @.str7, i32 0, i32 0), i32 72, i8* getelementptr inbounds ([23 x i8]* @__PRETTY_FUNCTION__.main, i32 0, i32 0)) #5
  unreachable
                                                  ; No predecessors!
  br label %68

; <label>:68                                      ; preds = %67, %65
  %69 = load i8** %base, align 8
  %70 = call i32 (i8*, ...)* @printf(i8* getelementptr inbounds ([15 x i8]* @.str11, i32 0, i32 0), i8* %69)
  %71 = load i8** %basename_input, align 8
  call void @free(i8* %71) #4
  %72 = load i8** %canonical, align 8
  call void @free(i8* %72) #4
  %73 = load i8** %buffer, align 8
  call void @free(i8* %73) #4
  ret i32 0
}

declare i32 @printf(i8*, ...) #1

; Function Attrs: nounwind
declare noalias i8* @malloc(i64) #2

declare void @perror(i8*) #1

; Function Attrs: noreturn nounwind
declare void @abort() #3

; Function Attrs: nounwind
declare i64 @readlink(i8*, i8*, i64) #2

; Function Attrs: nounwind
declare i8* @realpath(i8*, i8*) #2

; Function Attrs: nounwind
declare noalias i8* @strdup(i8*) #2

; Function Attrs: nounwind
declare i8* @dirname(i8*) #2

; Function Attrs: noreturn nounwind
declare void @__assert_fail(i8*, i8*, i32, i8*) #3

; Function Attrs: nounwind
declare void @free(i8*) #2

; Function Attrs: nounwind
declare i8* @__xpg_basename(i8*) #2

attributes #0 = { nounwind uwtable "less-precise-fpmad"="false" "no-frame-pointer-elim"="true" "no-frame-pointer-elim-non-leaf" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "stack-protector-buffer-size"="8" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #1 = { "less-precise-fpmad"="false" "no-frame-pointer-elim"="true" "no-frame-pointer-elim-non-leaf" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "stack-protector-buffer-size"="8" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #2 = { nounwind "less-precise-fpmad"="false" "no-frame-pointer-elim"="true" "no-frame-pointer-elim-non-leaf" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "stack-protector-buffer-size"="8" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #3 = { noreturn nounwind "less-precise-fpmad"="false" "no-frame-pointer-elim"="true" "no-frame-pointer-elim-non-leaf" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "stack-protector-buffer-size"="8" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #4 = { nounwind }
attributes #5 = { noreturn nounwind }

!llvm.ident = !{!0}

!0 = !{!"Ubuntu clang version 3.6.2-1 (tags/RELEASE_362/final) (based on LLVM 3.6.2)"}
