import org.gradle.api.tasks.Delete
import org.gradle.api.file.Directory

allprojects {
    repositories {
        google()
        mavenCentral()
    }
    
    // Set global SDK versions that many plugins pick up
    project.ext.set("compileSdkVersion", 36)
    project.ext.set("targetSdkVersion", 36)
    project.ext.set("minSdkVersion", 21)
}

// Put this OUTSIDE allprojects { } block
val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../build")
        .get()

rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

// Force specific versions to resolve lStar resource error
subprojects {
    project.configurations.all {
        resolutionStrategy {
            force("androidx.core:core:1.12.0")
            force("androidx.core:core-ktx:1.12.0")
            force("androidx.annotation:annotation:1.8.0")
        }
    }
}

// Force SDK 36 for all subprojects to satisfy plugin requirements
subprojects {
    afterEvaluate {
        val subproject = this
        if (subproject.extensions.findByType(com.android.build.gradle.BaseExtension::class.java) != null) {
            val android = subproject.extensions.getByType(com.android.build.gradle.BaseExtension::class.java)
            android.compileSdkVersion(36)
            android.defaultConfig {
                targetSdkVersion(36)
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
