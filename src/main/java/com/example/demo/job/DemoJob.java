package com.example.demo.job;

import com.xxl.job.core.handler.annotation.XxlJob;
import org.springframework.stereotype.Service;

@Service
public class DemoJob {

    @XxlJob("demoJobHandler")
    public void demoJobHandler() throws Exception {
        System.out.println("I'm job handler, I'm running...");
    }
}
