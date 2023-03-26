//
//  Thread.hpp
//  VideoLib
//
//  Created by 罗谨 on 2023/1/1.
//

#ifndef Thread_hpp
#define Thread_hpp

#include <stdio.h>
#include <thread>

class Thread {
public:
    Thread(){};
    ~Thread(){
        if (thread_) {
            Thread::Stop();
        }
    };
    int Start();
    void Stop(){
        abort_ = 1;
        if (thread_) {
            thread_->join();
            delete thread_;
            thread_ = NULL;
        }
    };
    
    virtual void Run()= 0;
protected:
    int abort_=0;
    std::thread *thread_ = NULL;
};

#endif /* Thread_hpp */


