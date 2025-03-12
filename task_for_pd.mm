#import <Foundation/Foundation.h>
#import <mach/mach.h>
#import <sys/sysctl.h>

pid_t find_pid_by_name(const char *process_name) {
    int mib[4] = { CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0 };
    size_t buffer_size = 0;
    
    if (sysctl(mib, 4, NULL, &buffer_size, NULL, 0) == -1) {
        NSLog(@"Failed to get buffer size");
        return -1;
    }
    
    struct kinfo_proc *processes = (struct kinfo_proc *)malloc(buffer_size);
    if (!processes) {
        NSLog(@"Failed to allocate memory");
        return -1;
    }
    
    if (sysctl(mib, 4, processes, &buffer_size, NULL, 0) == -1) {
        NSLog(@"Failed to retrieve process info");
        free(processes);
        return -1;
    }
    
    size_t num_processes = buffer_size / sizeof(struct kinfo_proc);
    
    for (size_t i = 0; i < num_processes; i++) {
        if (strcmp(processes[i].kp_proc.p_comm, process_name) == 0) {
            pid_t pid = processes[i].kp_proc.p_pid;
            free(processes);
            return pid;
        }
    }
    
    free(processes);
    return -1;
}

kern_return_t connect_to_process(pid_t pid, task_t *task) {
    kern_return_t kr;
    
    kr = task_for_pid(mach_task_self(), pid, task);
    if (kr != KERN_SUCCESS) {
        NSLog(@"Failed to get task for PID %d: %s", pid, mach_error_string(kr));
        return kr;
    }
    
    NSLog(@"Successfully connected to process with PID %d", pid);
    return KERN_SUCCESS;
}

int main(int argc, char *argv[]) {
    @autoreleasepool {
        const char *target_process_name = "SpringBoard";
        
        pid_t target_pid = find_pid_by_name(target_process_name);
        if (target_pid == -1) {
            NSLog(@"Process with name %s not found", target_process_name);
            return 1;
        }
        
        NSLog(@"Found process %s with PID %d", target_process_name, target_pid);
        
        task_t target_task;
        kern_return_t kr = connect_to_process(target_pid, &target_task);
        if (kr == KERN_SUCCESS) {
            NSLog(@"Successfully connected to process %s (PID: %d)", target_process_name, target_pid);
        } else {
            NSLog(@"Failed to connect to process");
        }
        
        return 0;
    }
}