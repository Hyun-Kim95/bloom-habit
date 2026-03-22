import com.android.build.gradle.LibraryExtension

// isar_flutter_libs가 compileSdk 30 고정 → release 리소스 링크(lStar) 실패 방지
gradle.beforeProject {
    if (name == "isar_flutter_libs") {
        afterEvaluate {
            extensions.findByType(LibraryExtension::class.java)?.apply {
                compileSdk = 34
                if (namespace == null || namespace!!.isEmpty()) {
                    namespace = "dev.isar.isar_flutter_libs"
                }
            }
        }
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
