enum GameonPlatform { playstation, xbox, pc, nintendo }

enum SubscriptionKind {
  psPlusEssential,
  psPlusExtra,
  psPlusPremium,
  gamePassCore,
  gamePassStandard,
  gamePassUltimate,
  pcGamePass,
  nintendoSwitchOnline,
}

const Map<GameonPlatform, Set<SubscriptionKind>> subscriptionsByPlatform = {
  GameonPlatform.playstation: {
    SubscriptionKind.psPlusEssential,
    SubscriptionKind.psPlusExtra,
    SubscriptionKind.psPlusPremium,
  },
  GameonPlatform.xbox: {
    SubscriptionKind.gamePassCore,
    SubscriptionKind.gamePassStandard,
    SubscriptionKind.gamePassUltimate,
  },
  GameonPlatform.pc: {
    SubscriptionKind.pcGamePass,
  },
  GameonPlatform.nintendo: {
    SubscriptionKind.nintendoSwitchOnline,
  },
};

enum CatalogSection {
  free,
  included,
  paid,
  deals,
  upcoming,
  newReleases,
  following,
  news,
}
