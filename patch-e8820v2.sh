#! /bin/bash

cat>./target/linux/ramips/dts/mt7621_zte_e8820v2.dts<<EOF
/dts-v1/;

#include "mt7621.dtsi"

#include <dt-bindings/gpio/gpio.h>
#include <dt-bindings/input/input.h>

/ {
	compatible = "zte,e8820v2", "mediatek,mt7621-soc";
	model = "ZTE E8820V2";

	aliases {
		label-mac-device = &gmac0;

		led-boot = &led_sys;
		led-failsafe = &led_sys;
		led-running = &led_sys;
		led-upgrade = &led_sys;
	};

	chosen {
		bootargs = "console=ttyS0,115200";
	};

	leds {
		compatible = "gpio-leds";

		led_sys: sys {
			label = "white:sys";
			gpios = <&gpio 29 GPIO_ACTIVE_LOW>;
		};

		led_power: power {
			label = "white:power";
			gpios = <&gpio 31 GPIO_ACTIVE_LOW>;
		};
	};

	keys {
		compatible = "gpio-keys";

		reset {
			label = "reset";
			gpios = <&gpio 18 GPIO_ACTIVE_LOW>;
			linux,code = <KEY_RESTART>;
		};

		wps {
			label = "wps";
			gpios = <&gpio 24 GPIO_ACTIVE_LOW>;
			linux,code = <KEY_WPS_BUTTON>;
		};
	};
};

&spi0 {
	status = "okay";

	flash@0 {
		compatible = "jedec,spi-nor";
		reg = <0>;
		spi-max-frequency = <10000000>;
		broken-flash-reset;

		partitions {
			compatible = "fixed-partitions";
			#address-cells = <1>;
			#size-cells = <1>;

			partition@0 {
				label = "u-boot";
				reg = <0x0 0x30000>;
				read-only;
			};

			partition@30000 {
				label = "u-boot-env";
				reg = <0x30000 0x10000>;
				read-only;
			};

			factory: partition@40000 {
				label = "factory";
				reg = <0x40000 0x10000>;
				read-only;
			};

			partition@50000 {
				compatible = "denx,uimage";
				label = "firmware";
				reg = <0x50000 0xfb0000>;
			};
		};
	};
};

&pcie {
	status = "okay";
};

&pcie0 {
	mt76@0,0 {
		reg = <0x0000 0 0 0 0>;
		mediatek,mtd-eeprom = <&factory 0x0000>;
		nvmem-cells = <&macaddr_factory_e000>;
		nvmem-cell-names = "mac-address";

		led {
			led-active-low;
		};
	};
};

&pcie1 {
	mt76@0,0 {
		reg = <0x0000 0 0 0 0>;
		mediatek,mtd-eeprom = <&factory 0x8000>;
		nvmem-cells = <&macaddr_factory_e006>;
		nvmem-cell-names = "mac-address";

		ieee80211-freq-limit = <5000000 6000000>;
		led {
			led-sources = <2>;
			led-active-low;
		};
	};
};

&gmac0 {
	nvmem-cells = <&macaddr_factory_e000>;
	nvmem-cell-names = "mac-address";
};

&switch0 {
	ports {
		port@0 {
			status = "okay";
			label = "lan1";
		};

		port@1 {
			status = "okay";
			label = "lan2";
		};

		port@2 {
			status = "okay";
			label = "lan3";
		};

		port@3 {
			status = "okay";
			label = "lan4";
		};

		port@4 {
			status = "okay";
			label = "wan";
			nvmem-cells = <&macaddr_factory_e006>;
			nvmem-cell-names = "mac-address";
		};
	};
};

&state_default {
	gpio {
		groups = "i2c", "uart2", "uart3", "wdt";
		function = "gpio";
	};
};

&factory {
	compatible = "nvmem-cells";
	#address-cells = <1>;
	#size-cells = <1>;

	macaddr_factory_e000: macaddr@e000 {
		reg = <0xe000 0x6>;
	};

	macaddr_factory_e006: macaddr@e006 {
		reg = <0xe006 0x6>;
	};
};
EOF

#增加LED
sed -i 's/^esac/zte,e8820v2)\
	ucidef_set_led_netdev "sys" "SYS_LED" "white:sys" "eth0" "tx rx"\
	ucidef_set_led_timer "power" "POWER_LED" "white:power" "100" "8000"\
	;;\
esac/g' ./target/linux/ramips/mt7621/base-files/etc/board.d/01_leds

	

#增加驱动

sed -i '$ a\\ndefine Device/zte_e8820v2\
  $(Device/dsa-migration)\
  $(Device/uimage-lzma-loader)\
  IMAGE_SIZE := 16064k\
  DEVICE_VENDOR := ZTE\
  DEVICE_MODEL := E8820V2\
  DEVICE_PACKAGES := kmod-mt7603 kmod-mt76x2 kmod-usb3 kmod-usb-ledtrig-usbport wpad-basic\
endef\
TARGET_DEVICES += zte_e8820v2' ./target/linux/ramips/image/mt7621.mk


