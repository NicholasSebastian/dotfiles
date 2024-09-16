# Dotfiles

My personal dotfiles containing all my configurations for my Linux system, development apps, etc.  

### Prerequisites

Make sure you have the following packages installed for this to work:
- stow
- python

### Installation

I do use GNU stow but not in a rather unconventional way.  
Make sure to use the included install.py script because my setup involves a weird mix of Stow and regular symbolic links. 
Maybe I'll tidy it up again in the future. But probably uneccessary as it works the way its supposed to already.

```sh
chmod +x install.py
./install.py
```

