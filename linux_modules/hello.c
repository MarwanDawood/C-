#include <linux/init.h>
#include <linux/module.h>

// @todo why I need __init here?
static int hello_init(void)
{
	printk(KERN_ALERT "Hello world, start of application \n");
	return 0;
}

static void hello_exit(void)
{
	printk(KERN_ALERT "Test Goodbye, end of application \n");
}

module_init(hello_init);
module_exit(hello_exit);

MODULE_LICENSE("Dual BSD/GPL");
