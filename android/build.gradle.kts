buildscript {
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath("com.android.tools.build:gradle:8.11.1")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:2.2.20")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.buildDir = file("../build")
subprojects {
    project.buildDir = file("${rootProject.buildDir}/${project.name}")
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.buildDir)
}

// ✅ ADD THIS BLOCK AT THE END
// Force all subprojects to use the root build directory
subprojects {
    project.layout.buildDirectory.set(
        rootProject.layout.buildDirectory.dir(project.name)
    )
}

// Ensure app module outputs are in the expected location
project(":app") {
    tasks.register<Copy>("copyApk") {
        from(layout.buildDirectory.dir("outputs/apk/release"))
        into(rootProject.layout.buildDirectory.dir("app/outputs/apk/release"))
        include("*.apk")
    }
    
    tasks.named("assembleRelease") {
        finalizedBy("copyApk")
    }
}