enum ListingStatus {
  draft,
  active,
  negotiating,
  sold,
  expired,
  cancelled,
}

class MarketListing {
  final String id;
  final String farmerId;
  final String farmerName;
  final String cropName;
  final double quantity;
  final String unit;
  final double pricePerUnit;
  final String quality;
  final String description;
  final List<String> images;
  final String location;
  final DateTime availableFrom;
  final DateTime availableUntil;
  final ListingStatus status;
  final int bids;
  final int views;
  final DateTime createdAt;
  final double? rating;
  final bool? isOrganic;
  final String? certification;
  final DeliveryOptions? deliveryOptions;
  final List<Bid>? bidsList;

  MarketListing({
    required this.id,
    required this.farmerId,
    required this.farmerName,
    required this.cropName,
    required this.quantity,
    required this.unit,
    required this.pricePerUnit,
    required this.quality,
    required this.description,
    required this.images,
    required this.location,
    required this.availableFrom,
    required this.availableUntil,
    required this.status,
    required this.bids,
    required this.views,
    required this.createdAt,
    this.rating,
    this.isOrganic,
    this.certification,
    this.deliveryOptions,
    this.bidsList,
  });

  factory MarketListing.fromJson(Map<String, dynamic> json) {
    return MarketListing(
      id: json['id'] ?? '',
      farmerId: json['farmerId'] ?? '',
      farmerName: json['farmerName'] ?? '',
      cropName: json['cropName'] ?? '',
      quantity: (json['quantity'] ?? 0).toDouble(),
      unit: json['unit'] ?? 'kg',
      pricePerUnit: (json['pricePerUnit'] ?? 0).toDouble(),
      quality: json['quality'] ?? '',
      description: json['description'] ?? '',
      images: List<String>.from(json['images'] ?? []),
      location: json['location'] ?? '',
      availableFrom: DateTime.parse(json['availableFrom'] ?? DateTime.now().toIso8601String()),
      availableUntil: DateTime.parse(json['availableUntil'] ?? DateTime.now().toIso8601String()),
      status: ListingStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ListingStatus.active,
      ),
      bids: json['bids'] ?? 0,
      views: json['views'] ?? 0,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      rating: json['rating']?.toDouble(),
      isOrganic: json['isOrganic'],
      certification: json['certification'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'farmerId': farmerId,
      'farmerName': farmerName,
      'cropName': cropName,
      'quantity': quantity,
      'unit': unit,
      'pricePerUnit': pricePerUnit,
      'quality': quality,
      'description': description,
      'images': images,
      'location': location,
      'availableFrom': availableFrom.toIso8601String(),
      'availableUntil': availableUntil.toIso8601String(),
      'status': status.name,
      'bids': bids,
      'views': views,
      'createdAt': createdAt.toIso8601String(),
      'rating': rating,
      'isOrganic': isOrganic,
      'certification': certification,
    };
  }

  double get totalValue => quantity * pricePerUnit;

  String get statusText {
    switch (status) {
      case ListingStatus.draft:
        return 'Draft';
      case ListingStatus.active:
        return 'Active';
      case ListingStatus.negotiating:
        return 'Negotiating';
      case ListingStatus.sold:
        return 'Sold';
      case ListingStatus.expired:
        return 'Expired';
      case ListingStatus.cancelled:
        return 'Cancelled';
    }
  }

  int get statusColor {
    switch (status) {
      case ListingStatus.draft:
        return 0xFF9E9E9E;
      case ListingStatus.active:
        return 0xFF4CAF50;
      case ListingStatus.negotiating:
        return 0xFFFFC107;
      case ListingStatus.sold:
        return 0xFF2196F3;
      case ListingStatus.expired:
        return 0xFFE53935;
      case ListingStatus.cancelled:
        return 0xFF757575;
    }
  }
}

class Bid {
  final String id;
  final String listingId;
  final String buyerId;
  final String buyerName;
  final double bidAmount;
  final double quantity;
  final String message;
  final DateTime createdAt;
  final BidStatus status;
  final String? counterOffer;

  Bid({
    required this.id,
    required this.listingId,
    required this.buyerId,
    required this.buyerName,
    required this.bidAmount,
    required this.quantity,
    required this.message,
    required this.createdAt,
    required this.status,
    this.counterOffer,
  });
}

enum BidStatus {
  pending,
  accepted,
  rejected,
  countered,
  expired,
}

class DeliveryOptions {
  final bool selfPickup;
  final bool localDelivery;
  final bool courierDelivery;
  final double? deliveryChargePerKm;
  final double? maxDeliveryDistance;
  final List<String>? availableTimeSlots;

  DeliveryOptions({
    required this.selfPickup,
    required this.localDelivery,
    required this.courierDelivery,
    this.deliveryChargePerKm,
    this.maxDeliveryDistance,
    this.availableTimeSlots,
  });
}

class Order {
  final String id;
  final String listingId;
  final String buyerId;
  final String buyerName;
  final String sellerId;
  final String sellerName;
  final String cropName;
  final double quantity;
  final String unit;
  final double pricePerUnit;
  final double totalAmount;
  final double? deliveryCharges;
  final double? taxes;
  final double finalAmount;
  final OrderStatus status;
  final String deliveryAddress;
  final DateTime orderDate;
  final DateTime? deliveryDate;
  final String? trackingId;
  final PaymentInfo? payment;

  Order({
    required this.id,
    required this.listingId,
    required this.buyerId,
    required this.buyerName,
    required this.sellerId,
    required this.sellerName,
    required this.cropName,
    required this.quantity,
    required this.unit,
    required this.pricePerUnit,
    required this.totalAmount,
    this.deliveryCharges,
    this.taxes,
    required this.finalAmount,
    required this.status,
    required this.deliveryAddress,
    required this.orderDate,
    this.deliveryDate,
    this.trackingId,
    this.payment,
  });
}

enum OrderStatus {
  pending,
  confirmed,
  processing,
  shipped,
  delivered,
  cancelled,
  refunded,
}

class PaymentInfo {
  final String id;
  final String orderId;
  final double amount;
  final String method;
  final PaymentStatus status;
  final DateTime transactionDate;
  final String? transactionId;
  final String? upiId;
  final String? bankAccount;

  PaymentInfo({
    required this.id,
    required this.orderId,
    required this.amount,
    required this.method,
    required this.status,
    required this.transactionDate,
    this.transactionId,
    this.upiId,
    this.bankAccount,
  });
}

enum PaymentStatus {
  pending,
  processing,
  completed,
  failed,
  refunded,
}
