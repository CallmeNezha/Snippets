#ifndef __TIMING_H__
#define __TIMING_H__

#include <iostream>
#include <time.h>

#define  DropTimebomb(msg)  auto bomb = Tools::TimeBomb(msg);

namespace Tools {

class TimeBomb final {
    
public:
    TimeBomb(const std::string& msg) {
        this->_timestamp = clock();  
        this->_msg = msg;
    }
    ~TimeBomb() { std::cout << this->_msg << " used: " \
        << double(clock() - this->_timestamp) * 1000.0 / CLOCKS_PER_SEC \
        << "ms" << std::endl;
    }

private:
    clock_t      _timestamp;
    std::string  _msg;
};

}
#endif //__TIMING_H__
