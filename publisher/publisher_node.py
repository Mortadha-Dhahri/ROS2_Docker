import rclpy
from rclpy.node import Node
from std_msgs.msg import String

class PublisherNode(Node):

    def __init__(self):
        super().__init__('publisher_node')

        # Publisher
        self.publisher_ = self.create_publisher(String, 'chatter', 10)

        # Subscriber (shutdown signal)
        self.shutdown_sub = self.create_subscription(
            String,
            '/shutdown_signal',
            self.shutdown_callback,
            10
        )

        self.timer = self.create_timer(1.0, self.publish_message)
        self.count = 0

    def publish_message(self):
        msg = String()
        msg.data = f'Hello ROS2: {self.count}'
        self.publisher_.publish(msg)
        self.get_logger().info(f'Publishing: "{msg.data}"')
        self.count += 1

    def shutdown_callback(self, msg):
        if msg.data == "STOP":
            self.get_logger().warn("Shutdown signal received. Stopping publisher...")
            rclpy.shutdown()


def main(args=None):
    rclpy.init(args=args)
    node = PublisherNode()

    try:
        rclpy.spin(node)
    except KeyboardInterrupt:
        pass

    node.destroy_node()
    rclpy.shutdown()


if __name__ == '__main__':
    main()