import rclpy
from rclpy.node import Node
from std_msgs.msg import String

class SubscriberNode(Node):
    def __init__(self):
        super().__init__('subscriber_node')

        self.count = 0

        self.subscription = self.create_subscription(
            String,
            'chatter',
            self.listener_callback,
            10
        )

        # signal publisher to request shutdown
        self.shutdown_pub = self.create_publisher(String, '/shutdown_signal', 10)

    def listener_callback(self, msg):
        self.count += 1
        self.get_logger().info(f'Received: "{msg.data}" (count={self.count})')

        if self.count > 30:
            self.get_logger().warn("Limit reached. Requesting publisher shutdown...")

            stop_msg = String()
            stop_msg.data = "STOP"
            self.shutdown_pub.publish(stop_msg)


def main(args=None):
    rclpy.init(args=args)
    node = SubscriberNode()
    rclpy.spin(node)
    node.destroy_node()
    rclpy.shutdown()


if __name__ == '__main__':
    main()